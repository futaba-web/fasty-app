class MypagesController < ApplicationController
  before_action :authenticate_user!

  def show
    @running = current_user.fasting_records.running.order(start_time: :desc).first
    @success_streak_days = calc_success_streak_days
  end

  private

  def calc_success_streak_days
    days = 0
    cursor = Time.zone.today
    loop do
      ok = current_user.fasting_records.where(success: true)
           .where(start_time: cursor.all_day).or(
             current_user.fasting_records.where(success: true).where(end_time: cursor.all_day)
           ).exists?
      break unless ok
      days += 1
      cursor -= 1.day
    end
    days
  end
end
