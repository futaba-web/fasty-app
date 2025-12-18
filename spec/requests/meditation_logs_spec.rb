require "rails_helper"

RSpec.describe "MeditationLogs", type: :request do
  describe "POST /meditation_logs" do
    let(:user) { create(:user) }
    let(:started_at) { Time.zone.parse("2025-01-01 09:00") }

    it "requires authentication" do
      post meditation_logs_path, params: { meditation_log: { duration_sec: 120 } }

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "creates a log for the signed-in user" do
      sign_in user

      expect {
        post meditation_logs_path, params: { meditation_log: { duration_sec: 180, started_at: started_at } }
      }.to change { user.meditation_logs.count }.by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body).to include("id")
    end

    it "returns errors for invalid payload" do
      sign_in user

      post meditation_logs_path, params: { meditation_log: { duration_sec: -10 } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to all(be_present)
    end
  end
end
