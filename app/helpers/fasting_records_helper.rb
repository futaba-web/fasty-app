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

  # === 絞り込みUI用 ===
  def status_filter_options
    [
      [ "すべて",      "" ],
      [ "目標達成",    "achieved" ],
      [ "未達成",      "unachieved" ],
      [ "進行中",      "in_progress" ]
    ]
  end

  # 旧パラメータ(success/failure)との互換
  def normalized_status_param(raw)
    case raw.to_s
    when "success" then "achieved"
    when "failure" then "unachieved"
    else raw
    end
  end

  # バッジ（達成/未達成/進行中）
  def status_badge(record)
    key =
      if record.respond_to?(:status_key)
        record.status_key
      elsif record.respond_to?(:status)
        (record.status rescue nil)&.to_sym
      end

    case key
    when :achieved   then content_tag(:span, "達成",   class: "badge badge--ok")
    when :unachieved then content_tag(:span, "未達成", class: "badge badge--ng")
    else                  content_tag(:span, "進行中", class: "badge badge--info")
    end
  end

  # コメント抜粋（任意）
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

  def snippet_plain_text(record, length: 60)
    text = record.respond_to?(:comment_text) ? record.comment_text.to_s.strip : ""
    truncate(text, length: length)
  end

  # ===== カレンダー用 =====

  # 外側ラッパー（aタグ）: モバイルは正方形レイアウト
  def day_cell_outer_classes(_day)
    "relative block pb-[100%] sm:pb-0"
  end

  # 内側（実表示）: base スタイル + todayリング
  def day_cell_classes(day, target_month)
    is_today = (day == Time.zone.today)

    base = [
      "absolute inset-0",
      "rounded-xl flex flex-col gap-2 p-2 cursor-pointer",
      # ベース
      "bg-white ring-1 ring-stone-200 shadow-sm",
      # 変化
      "transition-colors transition-transform duration-150",
      "hover:bg-sky-50 hover:ring-sky-300 hover:shadow-md hover:shadow-sky-100/60",
      "focus-visible:outline-none focus-visible:bg-sky-50",
      "focus-visible:ring-2 focus-visible:ring-sky-400 focus-visible:shadow-lg",
      "active:bg-sky-100 active:shadow",
      "hover:-translate-y-[1px] active:scale-[0.99] motion-reduce:transform-none",
      # デスクトップでは最低高を確保
      "sm:static sm:min-h-[96px]"
    ]
    base << "ring-sky-200" if is_today

    klass = base.join(" ")
    day.month == target_month ? "#{klass} text-stone-800" : "#{klass} text-stone-400"
  end

  # モバイル幅でセル背景色を状態別に変える（PC幅では白に戻す）
  # 達成=!bg-green-50 / 途中=!bg-amber-50 / 未達=!bg-rose-50
  # ! を付けて bg-white を確実に上書き。PC幅では stone に戻す。
  def mobile_color_classes(record)
    return "" unless record

    if record.success == true
      "!bg-green-50 !ring-green-200 sm:bg-white sm:ring-stone-200"
    elsif record.end_time.nil?
      "!bg-amber-50 !ring-amber-200 sm:bg-white sm:ring-stone-200"
    else
      "!bg-rose-50 !ring-rose-200 sm:bg-white sm:ring-stone-200"
    end
  end

  # 旧来の◯/△/×バッジ（凡例やPCセル内表示）
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

  # 汎用バッジ
  def tailwind_badge(text, color_classes)
    content_tag(:span, text,
      class: "inline-flex items-center justify-center text-[12px] px-2 py-0.5 rounded-lg ring-1 #{color_classes}")
  end
  alias badge tailwind_badge

  private

  def to_time_in_zone(dt)
    return dt.in_time_zone if dt.respond_to?(:in_time_zone)
    Time.zone.parse(dt.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
