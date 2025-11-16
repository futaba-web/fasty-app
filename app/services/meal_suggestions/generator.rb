# app/services/meal_suggestions/generator.rb
module MealSuggestions
  class Generator
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
      system_prompt = <<~PROMPT
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

      # モデルに渡すコンテキスト（人間が読んで分かる形にする）
      user_context_text = <<~CONTEXT
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

        上記の情報をもとに、指定された JSON フォーマットで、
        1日の朝食・昼食・夕食と、全体の注意点を提案してください。
      CONTEXT

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: system_prompt },
            { role: "user",   content: user_context_text }
          ],
          # ちょっとだけ揺らぎを持たせる
          temperature: 0.7,
          # JSON が途中で切れない程度の上限
          max_tokens: 800
          # ※ 必要なら response_format を追加する余地あり
        }
      )

      raw    = response.dig("choices", 0, "message", "content")
      parsed = safe_parse_json(raw)
      normalize_content(parsed)
    end

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
