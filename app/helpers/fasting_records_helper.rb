# app/helpers/fasting_records_helper.rb
module FastingRecordsHelper
  WDAY_JA = %w[日 月 火 水 木 金 土].freeze

  # 例: "2025/09/14(日) 14時18分"
  def fmt_jp(dt)
    return "-" if dt.blank?
    t = to_time_in_zone(dt)
    return "-" if t.nil?
    t.strftime("%Y/%m/%d(#{WDAY_JA[t.wday]}) %H時%M分")
  end

  # 一覧用：日付のみ（例: "2025/09/14(日)"）
  def list_date(dt)
    return "-" if dt.blank?
    t = to_time_in_zone(dt)
    return "-" if t.nil?
    t.strftime("%Y/%m/%d(#{WDAY_JA[t.wday]})")
  end

  # === 絞り込みUI用（パーシャルから参照） ===
  def status_filter_options
    [
      ["すべて",      ""],
      ["目標達成",    "achieved"],
      ["未達成",      "unachieved"],
      ["進行中",      "in_progress"]
    ]
  end

  # 旧パラメータ(success/failure)との互換
  def normalized_status_param(raw)
    case raw.to_s
    when "success"   then "achieved"
    when "failure"   then "unachieved"
    else raw
    end
  end

  # バッジ（達成/未達成/進行中）— 既存クラス維持
  def status_badge(record)
    key =
      if record.respond_to?(:status_key)
        record.status_key
      elsif record.respond_to?(:status)
        (record.status rescue nil)&.to_sym
      end

    case key
    when :achieved
      content_tag(:span, "達成",    class: "badge badge--ok")
    when :unachieved
      content_tag(:span, "未達成",  class: "badge badge--ng")
    else
      content_tag(:span, "進行中",  class: "badge badge--info")
    end
  end

  # コメントの抜粋（2行想定。CSS で line-clamp）
  def comment_snippet(record, length: 60)
    text = record.respond_to?(:comment_text) ? record.comment_text.to_s.strip : ""
    return "".html_safe if text.blank?

    content_tag(:div, class: "record-comment", title: text) do
      safe_join([
        content_tag(:span, "💬", aria: { hidden: true }),
        content_tag(:span, " "),
        content_tag(:span, truncate(text, length: length))
      ])
    end
  end

  # 素のテキストだけ（任意）
  def snippet_plain_text(record, length: 60)
    text = record.respond_to?(:comment_text) ? record.comment_text.to_s.strip : ""
    truncate(text, length: length)
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

  # =========================
  # カレンダー用ヘルパ
  # =========================

  # 状態 → 記号・色（Tailwind semantic）
  # success=green / ongoing=amber / fail=rose
  def fasting_badge_for(record)
    return if record.nil?

    if record.success == true
      tailwind_badge("◯", "bg-green-100 text-green-700 ring-green-200")
    elsif record.end_time.nil?
      tailwind_badge("△", "bg-amber-100 text-amber-700 ring-amber-200")
    else
      tailwind_badge("×", "bg-rose-100 text-rose-700 ring-rose-200")
    end
  end

  # 汎用：Tailwindバッジ
  def tailwind_badge(text, color_classes)
    content_tag(:span, text,
      class: "inline-flex items-center justify-center text-[12px] px-2 py-0.5 rounded-lg ring-1 #{color_classes}")
  end
  alias badge tailwind_badge  # 互換目的（任意）

  # 日セルのスタイル
  # - 当月外は“文字色だけ”薄く（opacityは使わない）
  # - XS/SM/MDで高さ調整
  # - ホバー/フォーカスでセル背景を空色に変化させ、リングもスカイ系に変更
  # - 今日: 常時うっすらスカイのリング
  def day_cell_classes(day, target_month)
    is_today = (day == Time.zone.today)

    base = [
      "min-h-[68px] sm:min-h-[80px] md:min-h-[96px]",
      "p-2 rounded-xl flex flex-col gap-2 cursor-pointer",
      # ベース（可読性重視の白）
      "bg-white ring-1 ring-stone-200 shadow-sm",
      # 色が“はっきり”変わるホバー/フォーカス
      "transition-colors transition-transform duration-150",
      "hover:bg-sky-50 hover:ring-sky-300 hover:shadow-md hover:shadow-sky-100/60",
      "focus-visible:outline-none focus-visible:bg-sky-50",
      "focus-visible:ring-2 focus-visible:ring-sky-400 focus-visible:shadow-lg",
      # モバイルのタップ時フィードバック
      "active:bg-sky-100 active:shadow",
      # わずかなリフト
      "hover:-translate-y-[1px] active:scale-[0.99] motion-reduce:transform-none"
    ]
    base << "ring-sky-200" if is_today

    klass = base.join(" ")
    day.month == target_month ? "#{klass} text-stone-800" : "#{klass} text-stone-400"
  end

  private

  def to_time_in_zone(dt)
    return dt.in_time_zone if dt.respond_to?(:in_time_zone)
    Time.zone.parse(dt.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
