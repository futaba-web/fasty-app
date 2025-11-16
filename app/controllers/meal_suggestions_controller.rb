class MealSuggestionsController < ApplicationController
  before_action :authenticate_user!

  def show
    @today      = Date.current
    @insight    = FastingInsight.build_for(current_user)
    @suggestion = current_user.meal_suggestions.find_by(target_date: @today)
  end

  def create
    today   = Date.current
    insight = FastingInsight.build_for(current_user)

    planner = Ai::MealPlanner.new(current_user, insight)
    content = planner.build

    if content.blank?
      redirect_to meal_suggestion_path,
                  alert: "AIによる食事提案の生成に失敗しました。時間をおいて再度お試しください。"
      return
    end

    suggestion = current_user.meal_suggestions.find_or_initialize_by(target_date: today)
    suggestion.phase   = "insight_based"
    suggestion.content = content

    if suggestion.save
      redirect_to meal_suggestion_path, notice: "今日の食事提案を作成しました。"
    else
      redirect_to meal_suggestion_path, alert: "提案の保存に失敗しました。"
    end
  end
end
