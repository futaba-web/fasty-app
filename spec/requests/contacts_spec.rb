# spec/requests/contacts_spec.rb
require "rails_helper"

RSpec.describe "Contacts", type: :request do
  describe "GET /contacts/new" do
    it "returns 4xx client error (アクセス制御下であることを確認)" do
      get "/contacts/new"
      expect(response.status).to be_between(400, 499)
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

    it "returns 4xx client error (アクセス制御下であることを確認)" do
      post "/contacts", params: params
      expect(response.status).to be_between(400, 499)
    end
  end
end
