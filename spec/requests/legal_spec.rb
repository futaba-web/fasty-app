# spec/requests/legal_spec.rb
require "rails_helper"

RSpec.describe "Legals", type: :request do
  describe "GET /terms" do
    it "returns http forbidden" do
      get "/terms"
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /privacy" do
    it "returns http forbidden" do
      get "/privacy"
      expect(response).to have_http_status(:forbidden)
    end
  end
end
