# frozen_string_literal: true
require "rails_helper"

RSpec.describe "MeditationSummaries", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  it "returns success response" do
    get meditation_summary_path

    expect(response).to have_http_status(:success)
  end
end
