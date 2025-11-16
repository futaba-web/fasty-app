require 'rails_helper'

RSpec.describe "MealSuggestions", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/meal_suggestions/show"
      expect(response).to have_http_status(:success)
    end
  end

end
