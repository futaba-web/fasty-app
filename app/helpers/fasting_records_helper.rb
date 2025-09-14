# app/helpers/fasting_records_helper.rb
module FastingRecordsHelper
  WDAY_JA = %w[日 月 火 水 木 金 土].freeze

  # 例: "2025/09/14(日) 14時18分"
  def fmt_jp(dt)
    return "-" if dt.blank?
    t = to_time_in_zone(dt)
    t.strftime("%Y/%m/%d(#{WDAY_JA[t.wday]}) %H時%M分")
  end

  # 一覧用：日付のみ（例: "2025/09/14(日)"）
  def list_date(dt)
    return "-" if dt.blank?
    t = to_time_in_zone(dt)
    t.strftime("%Y/%m/%d(#{WDAY_JA[t.wday]})")
  end

  # バッジ（達成/未達成/進行中）
  def status_badge(record)
    base = "inline-flex items-center whitespace-nowrap rounded-full px-2 py-0.5 text-xs font-semibold ring-1"
    case record.status_key
    when :achieved
      content_tag(:span, "達成", class: "badge badge--ok")
    when :unachieved
      content_tag(:span, "未達成", class: "badge badge--ng")
    else
      content_tag(:span, "進行中", class: "badge badge--info")
    end
  end

  # コメントの抜粋（2行想定。CSS で line-clamp する想定）
  def comment_snippet(record, length: 60)
    text = record.comment_text.to_s.strip
    return "".html_safe if text.blank?

    content_tag(:div, class: "record-comment", title: text) do
      content_tag(:span, "💬", aria: { hidden: true }) <<
      content_tag(:span, " ") <<
      content_tag(:span, truncate(text, length: length))
    end
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

  # 進行中の経過時間用（to が nil のときは現在時刻で計算）
  def fmt_elapsed(from, to = nil)
    return "-" if from.blank?
    fmt_duration(from, to || Time.current)
  end

  private

  def to_time_in_zone(dt)
    dt.respond_to?(:in_time_zone) ? dt.in_time_zone : Time.zone.parse(dt.to_s)
  end
end
