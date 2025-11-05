require 'rails_helper'

RSpec.describe "MeditationSummaries", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/meditation_summaries/show"
      expect(response).to have_http_status(:success)
    end
  end

end
