# spec/requests/contacts_spec.rb
require "rails_helper"

RSpec.describe "Contacts", type: :request do
  describe "GET /contacts/new" do
    it "returns http forbidden" do
      get "/contacts/new"
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /contacts" do
    let(:params) do
      {
        contact: {
          name:  "テストユーザー",
          email: "test@example.com",
          body:  "お問い合わせ本文です。"
        }
      }
    end

    it "returns http forbidden" do
      post "/contacts", params: params
      expect(response).to have_http_status(:forbidden)
    end
  end
end
