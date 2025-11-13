# spec/requests/legal_spec.rb
require "rails_helper"

RSpec.describe "Legals", type: :request do
  describe "GET /terms" do
    it "returns 4xx client error (アクセス制御下であることを確認)" do
      get "/terms"
      expect(response.status).to be_between(400, 499)
    end
  end

  describe "GET /privacy" do
    it "returns 4xx client error (アクセス制御下であることを確認)" do
      get "/privacy"
      expect(response.status).to be_between(400, 499)
    end
  end
end
