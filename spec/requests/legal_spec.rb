require 'rails_helper'

RSpec.describe "Legals", type: :request do
  describe "GET /terms" do
    it "returns http success" do
      get "/legal/terms"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /privacy" do
    it "returns http success" do
      get "/legal/privacy"
      expect(response).to have_http_status(:success)
    end
  end

end
