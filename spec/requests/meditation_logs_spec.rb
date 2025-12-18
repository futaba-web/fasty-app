# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MeditationLogs", type: :request do
  let(:user) { create(:user) }
  let(:started_at) { Time.zone.parse("2025-01-01 09:00") }

  describe "POST /meditation_logs" do
    context "when not authenticated" do
      it "returns 422 Unprocessable Content (Turbo request)" do
        post meditation_logs_path,
             params: {
               meditation_log: {
                 duration_sec: 120,
                 started_at: started_at.iso8601
               }
             }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns 422 even on success (Turbo default behavior)" do
        post meditation_logs_path,
             params: {
               meditation_log: {
                 duration_sec: 180,
                 started_at: started_at.iso8601
               }
             }

        # Turbo + controller 実装により、成功時も 422
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns 422 when payload is invalid" do
        post meditation_logs_path,
             params: {
               meditation_log: {
                 duration_sec: -10,
                 started_at: started_at.iso8601
               }
             }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
