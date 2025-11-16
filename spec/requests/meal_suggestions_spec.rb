# spec/requests/meal_suggestions_spec.rb
require "rails_helper"

RSpec.describe "MealSuggestions", type: :request do
  describe "GET /meal_suggestion" do
    it "redirects to login when not signed in" do
      get meal_suggestion_path

      expect(response).to have_http_status(:found) # 302
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
