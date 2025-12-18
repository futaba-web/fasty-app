# spec/requests/meditation_summaries_spec.rb
require "rails_helper"

RSpec.describe "MeditationSummaries", type: :request do
  describe "GET /meditation_summaries/show" do
    it "returns 4xx client error (アクセス制御下であることを確認)" do
      get "/meditation_summaries/show"
      expect(response.status).to be_between(400, 499)
    end
  end

  describe "GET /meditation_summary" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "aggregates duration_sec when minute fields are missing" do
      create(:meditation_log, user: user, duration_sec: 150)

      get meditation_summary_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("2.5")
    end
  end
end
