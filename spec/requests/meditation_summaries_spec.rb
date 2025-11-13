# spec/requests/meditation_summaries_spec.rb
require "rails_helper"

RSpec.describe "MeditationSummaries", type: :request do
  describe "GET /meditation_summaries/show" do
    it "returns http forbidden" do
      get "/meditation_summaries/show"
      expect(response).to have_http_status(:forbidden)
    end
  end
end
