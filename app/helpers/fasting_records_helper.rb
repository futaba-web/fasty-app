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

  # === 絞り込みUI用
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

  # ========== バッジ（PC用） ==========
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
  alias badge tailwind_badge

  # ========== モバイル用：日付数字の“丸チップ”を色分け ==========
  # recordの状態に応じて日付数字をカラーリング（sm未満のみ表示）
  # - 成功: 緑 / 途中: 黄 / 未達: 赤 / 記録なし: デフォルト
  def mobile_colored_day_number(day, record, today:)
    base = "inline-flex sm:hidden items-center justify-center w-7 h-7 rounded-full text-[13px] font-medium"
    classes =
      if record.present?
        if record.success == true
          "bg-green-500/90 text-white"
        elsif record.end_time.nil?
          "bg-amber-500/90 text-white"
        else
          "bg-rose-500/90 text-white"
        end
      else
        "bg-transparent text-stone-900"
      end

    # 今日の強調（枠線）※色は状態そのまま、枠だけ淡いスカイ
    classes += " ring-2 ring-sky-300" if today

    content_tag(:span, day.day, class: "#{base} #{classes}")
  end

  # PC用の日付（sm以上で表示）
  def desktop_day_number(day, today:)
    color = today ? "text-sky-700" : "text-stone-900"
    content_tag(:span, day.day, class: "hidden sm:inline text-sm font-medium #{color}")
  end

  # 日セル（共通）
  # 当月外は“文字色だけ”薄く（opacityは使わない）
  def day_cell_classes(day, target_month)
    is_today = (day == Time.zone.today)
    base = [
      # モバイルは正方形を意識して高さ控えめ / sm以降はゆとり
      "min-h-[58px] sm:min-h-[76px] md:min-h-[96px]",
      "p-2 rounded-xl flex flex-col gap-2 cursor-pointer",
      "bg-white ring-1 ring-stone-200 shadow-sm",
      "transition-colors transition-transform duration-150",
      "hover:bg-sky-50 hover:ring-sky-300 hover:shadow-md hover:shadow-sky-100/60",
      "focus-visible:outline-none focus-visible:bg-sky-50",
      "focus-visible:ring-2 focus-visible:ring-sky-400 focus-visible:shadow-lg",
      "active:bg-sky-100 active:shadow",
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
