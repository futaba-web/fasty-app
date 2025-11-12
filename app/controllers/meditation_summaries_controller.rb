# app/controllers/meditation_summaries_controller.rb
class MeditationSummariesController < ApplicationController
  before_action :authenticate_user!

  def show
    @period = (params[:p] == "month") ? :month : :week

    to   = Time.zone.now.end_of_day
    from = (@period == :week ? (to - 6.days) : (to - 29.days)).beginning_of_day

    logs = MeditationLog.where(user_id: current_user.id)
                        .where(
                          MeditationLog.arel_table[:started_at].between(from..to)
                          .or(MeditationLog.arel_table[:created_at].between(from..to))
                        )
                        .order(:created_at)

    @total_minutes = logs.sum { |l| duration_minutes_of(l) }
    @count         = logs.size
    @avg_minutes   = @count.positive? ? (@total_minutes.to_f / @count).round(1) : 0.0

    # 日別合計（グラフ/表用）
    buckets = (from.to_date..to.to_date).map { |d| [ d, 0 ] }.to_h
    logs.each do |l|
      d = (started_time_of(l) || l.try(:created_at) || Time.zone.now).to_date
      buckets[d] += duration_minutes_of(l)
    end
    @daily_minutes = buckets
    @logs = logs.reverse # 新しい順

    # ヘルパ的に内部メソッド
  end

  private

  def started_time_of(record)
    record.respond_to?(:started_at) ? record.started_at : record.try(:created_at)
  end

  def duration_minutes_of(record)
    if record.respond_to?(:duration_min) && record.duration_min
      record.duration_min
    elsif record.respond_to?(:duration_minutes) && record.duration_minutes
      record.duration_minutes
    else
      0
    end
  end
end
