# app/helpers/fasting_records_helper.rb
module FastingRecordsHelper
  WDAY_JA = %w[日 月 火 水 木 金 土].freeze

  def fmt_jp(dt)
    return "-" if dt.blank?
    t = dt.respond_to?(:in_time_zone) ? dt.in_time_zone : Time.zone.parse(dt.to_s)
    t.strftime("%Y/%m/%d(#{WDAY_JA[t.wday]}) %H時%M分")
  end

  # 終了が開始より前/未設定なら "-" を返す、安全版
  def fmt_duration(from, to)
    return "-" if from.blank? || to.blank?
    sec = (to - from).to_i
    return "-" if sec.negative?

    h, rem = sec.divmod(3600)
    m, _   = rem.divmod(60)
    "#{h}時間#{m}分"
  end

  # 進行中の経過時間を出したいとき用（to が nil のときは現在時刻で計算）
  def fmt_elapsed(from, to = nil)
    return "-" if from.blank?
    fmt_duration(from, to || Time.current)
  end
end
