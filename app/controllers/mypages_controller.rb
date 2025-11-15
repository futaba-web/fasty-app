# app/controllers/mypages_controller.rb
class MypagesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @running = current_user.fasting_records.running.order(start_time: :desc).first
    @success_streak_days = calc_success_streak_days
  end

  def update_line_notify
    @user = current_user

    # 念のため保険：LINE連携していないユーザーは弾く
    unless @user.line_connected?
      redirect_to mypage_path, alert: "LINE連携しているユーザーのみ設定できます。"
      return
    end

    if @user.update(line_notify_params)
      redirect_to mypage_path, notice: "LINE通知設定を更新しました。"
    else
      # show用のインスタンス変数も復元しておく
      @running = current_user.fasting_records.running.order(start_time: :desc).first
      @success_streak_days = calc_success_streak_days

      flash.now[:alert] = "LINE通知設定の更新に失敗しました。"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def calc_success_streak_days
    days = 0
    cursor = Time.zone.today

    loop do
      ok = current_user.fasting_records.where(success: true)
           .where(start_time: cursor.all_day).or(
             current_user.fasting_records.where(success: true)
                         .where(end_time: cursor.all_day)
           ).exists?

      break unless ok

      days += 1
      cursor -= 1.day
    end

    days
  end

  def line_notify_params
    params.require(:user).permit(:line_notify_enabled)
  end
end
