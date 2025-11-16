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
      insight = FastingInsight.build_for(@user)
      phase   = detect_phase(insight)
      content = generate_content(insight, phase)

      suggestion = @user.meal_suggestions.find_or_initialize_by(target_date: @date)
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
        あなたはファスティング後の回復食に詳しい栄養士です。
        以下のユーザーの断食状況を読み取り、その日におすすめの1日の食事プランを提案してください。
        日本語で出力し、JSONだけを返してください。説明文や前後の文章は書かないでください。

        出力フォーマット（必ずこのキー構造で）:
        {
          "breakfast": { "menu": "...", "why": "...", "note": "..." },
          "lunch":     { "menu": "...", "why": "...", "note": "..." },
          "dinner":    { "menu": "...", "why": "...", "note": "..." },
          "alerts":    ["...", "..."]
        }

        制約:
        - メニューは日本の家庭で再現しやすい、やさしい和食中心。
        - 断食直後 1〜3 日は「消化にやさしい・少量・よく噛む」を強調。
        - ファスティング時間が短い/回数が少ない場合は、ライトで続けやすい提案にする。
        - 医療行為や病名、薬の具体名には触れず、
          「体調に不安がある場合は専門家に相談」といった一般的な注意にとどめる。
      PROMPT

      user_context = {
        phase: phase,
        total_hours_7days:   insight.total_hours_7days,
        avg_hours_7days:     insight.avg_hours_7days,
        success_rate_7days:  insight.success_rate_7days,
        streak_days:         insight.streak_days,
        currently_fasting:   insight.currently_fasting,
        days_since_last_end: insight.days_since_last_end
      }

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: system_prompt },
            { role: "user",   content: user_context.to_json }
          ]
        }
      )

      raw = response.dig("choices", 0, "message", "content")
      parsed = safe_parse_json(raw)
      normalize_content(parsed)
    end

    def safe_parse_json(text)
      JSON.parse(text)
    rescue JSON::ParserError
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
