# app/services/fasting_insight.rb
class FastingInsight
  # ユーザーごとのファスティング状況の集計結果をまとめる Struct
  Result = Struct.new(
    :currently_fasting,     # 現在ファスティング中か
    :total_hours_7days,     # 直近7日間の合計ファスティング時間
    :avg_hours_7days,       # 直近7日間の平均ファスティング時間
    :success_rate_7days,    # 直近7日間の「成功率」
    :streak_days,           # 連続成功日数
    :days_since_last_end,   # 最後のファスティング終了からの日数
    :last_target_hours,     # 直近の目標時間（時間）
    keyword_init: true
  )

  def self.build_for(user, now: Time.current)
    new(user, now:).build
  end

  def initialize(user, now: Time.current)
    @user = user
    @now  = now
  end

  def build
    records_7days = fasting_in_last_7_days

    total_hours = records_7days.sum { |r| duration_hours(r) }
    avg_hours   = records_7days.present? ? (total_hours / records_7days.size.to_f).round(1) : 0.0

    successes    = records_7days.count { |r| success?(r) }
    success_rate = records_7days.present? ? (successes.to_f / records_7days.size).round(2) : 0.0

    last_finished = @user.fasting_records
                         .where.not(end_time: nil)
                         .order(end_time: :desc)
                         .first

    days_since_last_end =
      if last_finished&.end_time
        (@now.to_date - last_finished.end_time.to_date).to_i
      else
        nil
      end

    Result.new(
      currently_fasting:      currently_fasting?,
      total_hours_7days:      total_hours,
      avg_hours_7days:        avg_hours,
      success_rate_7days:     success_rate,
      streak_days:            streak_days(records_7days),
      days_since_last_end:    days_since_last_end,
      last_target_hours:      last_finished&.target_hours # ← カラム名は実際に合わせて変更
    )
  end

  private

  # 直近7日間に開始したファスティングレコード
  def fasting_in_last_7_days
    range = (@now.beginning_of_day - 6.days)..@now.end_of_day
    @user.fasting_records.where(start_time: range)
  end

  # ファスティング時間（時間単位）を算出
  def duration_hours(record)
    return 0.0 unless record.end_time

    ((record.end_time - record.start_time) / 1.hour).round(1)
  end

  # 「成功」とみなす条件
  # target_hours カラム名は Fasty の実装に合わせて変更してOK
  def success?(record)
    return false unless record.end_time

    target = record.try(:target_hours)
    return false unless target.present?

    duration_hours(record) >= target.to_f * 0.9 # 90%以上達成で成功扱い（あとで調整可）
  end

  # 現在ファスティング中か（end_time が nil のレコードがあるか）
  def currently_fasting?
    @user.fasting_records.where(end_time: nil).exists?
  end

  # 直近7日間の「連続成功日数」を計算
  def streak_days(records_7days)
    by_day = records_7days.group_by { |r| r.start_time.to_date }

    days = (0..6).map { |i| (@now.to_date - i) } # 今日から過去7日ぶん
    streak = 0

    days.each do |day|
      records = by_day[day] || []
      # その日のどれか1つでも success? なら「その日は成功」
      break unless records.any? { |r| success?(r) }

      streak += 1
    end

    streak
  end
end
