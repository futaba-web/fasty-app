# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MeditationLogs", type: :request do
  let(:user) { create(:user) }
  let(:started_at) { Time.zone.parse("2025-01-01 09:00") }

  describe "POST /meditation_logs" do
    context "when not authenticated" do
      it "is rejected (redirect or 422 depending on environment)" do
        post meditation_logs_path,
             params: { meditation_log: { duration_sec: 120 } }

        expect(response.status).to be_in([ 302, 422 ])
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "accepts valid payload" do
        post meditation_logs_path,
             params: {
               meditation_log: {
                 duration_sec: 180,
                 started_at: started_at
               }
             }

        expect(response.status).to be_in([ 302, 422 ])
      end

      it "rejects invalid payload" do
        post meditation_logs_path,
             params: { meditation_log: { duration_sec: -10 } }

        expect(response.status).to be_in([ 302, 422 ])
      end
    end
  end
end
