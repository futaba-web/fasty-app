# app/controllers/meal_suggestions_controller.rb
class MealSuggestionsController < ApplicationController
  before_action :authenticate_user!

  def show
    @today      = Date.current
    @insight    = FastingInsight.build_for(current_user)
    @suggestion = current_user.meal_suggestions.find_by(target_date: @today)
  end

  def create
    today = Date.current

    suggestion = MealSuggestions::Generator.new(
      current_user,
      target_date: today
    ).call

    redirect_to meal_suggestion_path,
                notice: "今日の食事提案を作成しました。"
  rescue StandardError
    redirect_to meal_suggestion_path,
                alert: "AIによる食事提案の生成に失敗しました。時間をおいて再度お試しください。"
  end
end
