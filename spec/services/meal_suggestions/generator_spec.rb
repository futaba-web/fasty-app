# spec/services/meal_suggestions/generator_spec.rb
require "rails_helper"

RSpec.describe MealSuggestions::Generator, type: :service do
  let(:user)        { create(:user) }
  let(:target_date) { Date.new(2025, 1, 1) }

  # FastingInsight は「それっぽいオブジェクト」でOKなのでゆるい double にする
  let(:insight_double) do
    double(
      "FastingInsight",
      total_hours_7days:   16.0,
      avg_hours_7days:     2.3,
      success_rate_7days:  0.6,
      streak_days:         2,
      currently_fasting:   false,
      days_since_last_end: 1
    )
  end

  # OpenAI から返ってきたと想定する JSON 文字列
  let(:response_json) do
    {
      breakfast: {
        menu: "具だくさん味噌汁と柔らかいおかゆ",
        why:  "断食後の胃腸に負担をかけず、水分とミネラルを補給できるためです。",
        note: "よく噛んでゆっくり食べ、8分目を意識しましょう。"
      },
      lunch: {
        menu: "温野菜とささみのサラダ、少量の玄米",
        why:  "タンパク質と食物繊維をバランスよく補給できます。",
        note: "ドレッシングはかけすぎず、塩分と油分を控えめに。"
      },
      dinner: {
        menu: "豆腐と野菜のスープ、少量の白身魚",
        why:  "消化にやさしく、就寝前でも胃が重くなりにくい組み合わせです。",
        note: "就寝2〜3時間前までに食べ終えるようにしましょう。"
      },
      alerts: [
        "今日は揚げ物・アルコール・カフェインを控えめにしましょう。",
        "早食いを避け、1食20分以上かけてゆっくり味わってください。"
      ]
    }.to_json
  end

  let(:openai_response) do
    {
      "choices" => [
        { "message" => { "content" => response_json } }
      ]
    }
  end

  let(:logger) { instance_double(ActiveSupport::Logger, warn: nil) }

  before do
    # FastingInsight.build_for(user) をモック
    allow(FastingInsight).to receive(:build_for)
      .with(user)
      .and_return(insight_double)

    # OpenAIClient 自体が存在しない環境（CI / test）でも動くように、
    # テスト内で OpenAIClient 定数をダミークラスとして定義してからモックする
    stub_const("OpenAIClient", Class.new)

    allow(OpenAIClient).to receive(:chat)
      .and_return(openai_response)

    allow(Rails).to receive(:logger).and_return(logger)
  end

  it "creates a MealSuggestion for the given date with normalized content" do
    suggestion = described_class.new(user, target_date: target_date).call

    expect(suggestion).to be_persisted
    expect(suggestion.user).to eq(user)
    expect(suggestion.target_date).to eq(target_date)

    # フェーズ判定（days_since_last_end: 1 → recovery_day1 の想定）
    expect(suggestion.phase).to eq("recovery_day1")

    # JSON がちゃんと整形されて保存されていること
    content = suggestion.content

    expect(content["breakfast"]["menu"]).to eq("具だくさん味噌汁と柔らかいおかゆ")
    expect(content["lunch"]["why"]).to include("タンパク質と食物繊維")
    expect(content["alerts"]).to be_an(Array)
    expect(content["alerts"].size).to eq(2)
  end

  it "logs and raises when OpenAI client is disabled" do
    null_client = instance_double("NullClient", enabled?: false)

    expect {
      described_class.new(user, target_date: target_date, client: null_client).call
    }.to raise_error(described_class::AIUnavailableError)

    expect(logger).to have_received(:warn).with("[MealSuggestions] OpenAI is disabled. Skipping suggestion generation.")
    expect(user.meal_suggestions.where(target_date: target_date)).to be_blank
  end
end
