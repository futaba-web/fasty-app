# app/services/meal_suggestions/generator.rb
module MealSuggestions
  class Generator
    class AIUnavailableError < StandardError; end

    # どれくらいの期間のメニューを「なるべく被らせない対象」にするか
    RECENT_DAYS_FOR_VARIETY = 7

    def initialize(user, target_date: Date.current, client: OpenAIClient)
      @user   = user
      @date   = target_date
      @client = client
    end

    # メインエントリ
    # - FastingInsight を集計
    # - フェーズ判定
    # - OpenAI で提案生成
    # - MealSuggestion を upsert
    def call
      ensure_ai_available!

      insight = FastingInsight.build_for(user)
      phase   = detect_phase(insight)
      content = generate_content(insight, phase)

      suggestion = user.meal_suggestions.find_or_initialize_by(target_date: date)
      suggestion.phase   = phase
      suggestion.content = content

      suggestion.save!
      suggestion
    end

    private

    attr_reader :user, :date, :client

    def ensure_ai_available!
      return if ai_enabled?

      Rails.logger.warn("[MealSuggestions] OpenAI is disabled. Skipping suggestion generation.")
      raise AIUnavailableError, "OpenAI is not configured."
    end

    def ai_enabled?
      return client.enabled? if client.respond_to?(:enabled?)

      true
    end

    # ユーザーの状態から、ざっくりフェーズを決める
    def detect_phase(insight)
      return "fasting_now" if insight.currently_fasting

      days = insight.days_since_last_end
      return "recovery_day1"      if days.nil? || days <= 1
      return "recovery_day2"      if days == 2
      return "recovery_day3_plus" if days >= 3

      "history_based"
    end

    # OpenAI に投げて JSON を生成 → 正規化して返す
    def generate_content(insight, phase)
      recent_menus  = recent_menu_history
      current_menu  = current_menu_for_date

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: system_prompt },
            { role: "user",   content: build_user_prompt(insight, phase, recent_menus, current_menu) }
          ],
          # バリエーション重視で少し揺らぎ多め
          temperature: 0.85,
          max_tokens: 800
        }
      )

      raw    = response.dig("choices", 0, "message", "content")
      parsed = safe_parse_json(raw)
      normalize_content(parsed)
    end

    # ====== プロンプト関連 ===================================================

    def system_prompt
      <<~PROMPT
        あなたは「Fasty」というファスティング記録アプリの、
        やさしく落ち着いたトーンで話す日本人の栄養士です。

        役割:
        - ユーザーの断食状況や最近の記録を読み取り、
          「回復食」を中心とした1日の食事プランを提案してください。
        - 提案は、頑張りすぎず“続けやすさ”を大事にした内容にします。

        出力条件:
        - 出力は **必ず日本語のみ** にしてください。
        - 余計な説明文や前置き・あとがきは書かず、
          **JSONオブジェクト1つだけ** を返してください。
        - 改行やインデントはあってもよいですが、
          JSON 以外の文字は一切含めないでください。

        出力フォーマット（キー構造は厳守すること）:
        {
          "breakfast": { "menu": "...", "why": "...", "note": "..." },
          "lunch":     { "menu": "...", "why": "...", "note": "..." },
          "dinner":    { "menu": "...", "why": "...", "note": "..." },
          "alerts":    ["...", "..."]
        }

        各フィールドの意味:
        - menu: 具体的なメニュー名。家で再現しやすいシンプルな料理。
        - why: そのメニューが回復食として適している理由。
        - note: 食べ方の工夫（よく噛む・量は少なめ など）や、
                注意してほしいポイント。

        メニュー作成ルール:
        - ベースは和食寄り（おかゆ・味噌汁・煮物・湯豆腐・焼き魚など）で、
          やさしい味わいをイメージしてください。
        - 断食直後 1〜3 日は
          「消化にやさしい」「量は控えめ」「よく噛む」
          という方針を特に意識してください。
        - 最近のファスティング時間が短い／回数が少ない場合は、
          “がんばりすぎないライトな回復食” を提案してください。
        - アレルギーや持病は考慮できない前提とし、
          一般的な大人向けの提案にしてください。

        安全面について:
        - 医療行為の指示は行わず、病名や薬の固有名詞は出さないでください。
        - 体調に不安がある場合は「医師や専門家に相談してください」
          といった一般的な表現にとどめてください。
      PROMPT
    end

    def build_user_prompt(insight, phase, recent_menus, current_menu)
      phase_hint = case phase
      when "fasting_now"
                     "ユーザーは現在も断食中です。水分補給や、断食終了後1〜2食目のイメージを伝えてください。"
      when "recovery_day1"
                     "断食終了から1日以内の「回復食1日目」です。かなりやさしいメニューにしてください。"
      when "recovery_day2"
                     "回復食2日目です。まだ消化にやさしいものを中心にしつつ、少しずつ固形物を増やしてよい段階です。"
      when "recovery_day3_plus"
                     "回復食3日目以降です。通常食に近づけつつも、揚げ物や脂っこいもの・お酒は控えめにしてください。"
      else
                     "最近の記録を参考にしつつ、無理のないバランスのよい1日分のメニューを提案してください。"
      end

      recent_text =
        if recent_menus.present?
          recent_menus.map do |row|
            "#{row[:date]}: 朝=#{row[:breakfast]} / 昼=#{row[:lunch]} / 夜=#{row[:dinner]}"
          end.join("\n")
        else
          "（最近のメニュー履歴はありません）"
        end

      current_text =
        if current_menu
          c = current_menu
          <<~CURR
            なお、本日 (#{date}) に現在表示されているメニューは次の通りです。
            - 朝: #{c[:breakfast]}
            - 昼: #{c[:lunch]}
            - 夜: #{c[:dinner]}

            同じ日付で新しい案を出すときは、この内容とできるだけ被らないようにしてください。
          CURR
        else
          ""
        end

      <<~CONTEXT
        今日の日付: #{date}

        回復フェーズ:
        - phase: #{phase}
        - 説明: #{phase_hint}

        最近7日間のファスティング状況（サマリ）:
        - 合計ファスティング時間: #{insight.total_hours_7days.round(1)} 時間
        - 1日あたり平均:          #{insight.avg_hours_7days.round(1)} 時間
        - 成功率（7日間）:        #{(insight.success_rate_7days * 100).round}%#{' '}
        - 連続成功日数:            #{insight.streak_days} 日
        - 現在断食中か:            #{insight.currently_fasting}
        - 最後の断食終了からの日数: #{insight.days_since_last_end || '不明'} 日

        直近#{RECENT_DAYS_FOR_VARIETY}日間に、あなたがこのユーザーに提案したメニュー履歴は次の通りです（新しい日付から順に）:
        #{recent_text}

        #{current_text}

        バリエーションに関する重要な条件:
        - 上記の直近#{RECENT_DAYS_FOR_VARIETY}日分の menu と、できるだけ同じにならないようにしてください。
        - 同じ料理名（例: "おかゆ" や "湯豆腐"）を使う場合は、
          具材や味付け・組み合わせを変えて「別のバリエーション」になるようにしてください。
        - 朝・昼・夜で主食・たんぱく質・野菜のバランスや調理法を少し変えて、
          1日を通して単調にならないようにしてください。
        - 説明文（why, note）も、コピペのように同じ文章を繰り返さず、
          内容に合わせて言い回しを変えてください。

        上記をすべて踏まえて、指定された JSON フォーマットだけを出力してください。
      CONTEXT
    end

    # ====== 履歴取得ロジック ================================================

    # 直近 RECENT_DAYS_FOR_VARIETY 日分（当日を除く）のメニュー履歴
    # [{ date:, breakfast:, lunch:, dinner: }, ...] の配列で返す
    def recent_menu_history
      user.meal_suggestions
          .where("target_date < ? AND target_date >= ?", date, date - RECENT_DAYS_FOR_VARIETY)
          .order(target_date: :desc)
          .map do |ms|
        c = (ms.content || {}).with_indifferent_access
        {
          date:      ms.target_date,
          breakfast: c.dig(:breakfast, :menu).to_s,
          lunch:     c.dig(:lunch, :menu).to_s,
          dinner:    c.dig(:dinner, :menu).to_s
        }
      end
    end

    # 同じ日付の「現在表示中メニュー」（もう一案ボタン用）
    # まだ何もない場合は nil
    def current_menu_for_date
      ms = user.meal_suggestions.find_by(target_date: date)
      return nil unless ms

      c = (ms.content || {}).with_indifferent_access
      {
        breakfast: c.dig(:breakfast, :menu).to_s,
        lunch:     c.dig(:lunch, :menu).to_s,
        dinner:    c.dig(:dinner, :menu).to_s
      }
    end

    # ====== JSON パース & 正規化 ===========================================

    def safe_parse_json(text)
      JSON.parse(text)
    rescue JSON::ParserError, TypeError
      {}
    end

    # nil やキー抜けがあっても落ちないように整形
    def normalize_content(hash)
      h = (hash || {}).with_indifferent_access

      {
        "breakfast" => normalize_slot(h[:breakfast]),
        "lunch"     => normalize_slot(h[:lunch]),
        "dinner"    => normalize_slot(h[:dinner]),
        "alerts"    => Array(h[:alerts]).map(&:to_s)
      }
    end

    def normalize_slot(slot)
      s = (slot || {}).with_indifferent_access
      {
        "menu" => s[:menu].to_s,
        "why"  => s[:why].to_s,
        "note" => s[:note].to_s
      }
    end
  end
end
