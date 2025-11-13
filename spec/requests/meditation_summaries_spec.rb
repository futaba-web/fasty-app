# spec/requests/meditation_summaries_spec.rb
require "rails_helper"

RSpec.describe "MeditationSummaries", type: :request do
  describe "GET /meditation_summaries/show" do
    it "returns 4xx client error (アクセス制御下であることを確認)" do
      get "/meditation_summaries/show"
      expect(response.status).to be_between(400, 499)
    end
  end
end
