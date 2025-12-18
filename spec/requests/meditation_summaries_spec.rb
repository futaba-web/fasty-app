require "rails_helper"

RSpec.describe "MeditationSummaries", type: :request do
  it "redirects to sign-in when not authenticated" do
    get meditation_summary_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "aggregates duration_sec when minute fields are missing" do
    user = create(:user)
    sign_in user

    create(:meditation_log, user: user, duration_sec: 150)

    get meditation_summary_path
    follow_redirect!

    expect(response).to have_http_status(:success)
    expect(response.body).to include("2.5")
  end
end
