# app/models/meditation_log.rb
class MeditationLog < ApplicationRecord
  belongs_to :user

  validates :duration_sec, numericality: { greater_than_or_equal_to: 0 }

  # 週単位で便利に取れるスコープ（started_at があれば優先）
  scope :in_week, ->(time = Time.zone.now, week_starts: :monday) {
    s = time.beginning_of_week(week_starts).beginning_of_day
    e = s.end_of_week(week_starts).end_of_day
    if column_names.include?("started_at") && !where(started_at: nil).exists?
      where(started_at: s..e)
    else
      where(created_at: s..e)
    end
  }
end
