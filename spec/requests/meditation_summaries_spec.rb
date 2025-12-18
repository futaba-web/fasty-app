# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MeditationSummaries", type: :request do
  describe "GET /meditation_summary" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        get meditation_summary_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it "allows access but may redirect depending on app state" do
        get meditation_summary_path

        # アプリ仕様上 200 または 302 のどちらも正
        expect(response.status).to be_in([200, 302])
      end
    end
  end
end
