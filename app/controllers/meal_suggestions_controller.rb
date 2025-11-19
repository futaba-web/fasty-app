# app/controllers/meal_suggestions_controller.rb
class MealSuggestionsController < ApplicationController
  before_action :authenticate_user!

  def show
    @today      = Date.current
    @suggestion = current_user.meal_suggestions.find_by(target_date: @today)

    # 「このメニューでOK」→ 今日の日付をセッションに保存して決定状態にする
    if params[:confirm] == "true" && @suggestion.present?
      session[:meal_suggestion_confirmed_on] = @today.to_s
      redirect_to meal_suggestion_path and return
    end

    # 「メニューを選び直す」→ 決定状態を解除し、今日の提案を削除して初期状態へ
    if params[:reset] == "true"
      session.delete(:meal_suggestion_confirmed_on)
      @suggestion&.destroy
      redirect_to meal_suggestion_path and return
    end

    @insight   = FastingInsight.build_for(current_user)
    @confirmed = (session[:meal_suggestion_confirmed_on] == @today.to_s)
  end

  def create
    today = Date.current

    # 新しく提案を作るときは「決定状態」をリセットしておく
    session.delete(:meal_suggestion_confirmed_on)

    MealSuggestions::Generator.new(
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
