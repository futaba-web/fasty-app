# app/helpers/application_helper.rb
module ApplicationHelper
  def display_name(user)
    return "" unless user
    user.name.present? ? user.name : user.email.to_s.split("@").first
  end

  def home_path
    user_signed_in? ? authenticated_root_path : unauthenticated_root_path
  end

  # datetime-local 用（タイムゾーン無しの "YYYY-MM-DDTHH:MM:SS"）
  def datetime_local_value(time)
    return "" if time.blank?
    time.in_time_zone.strftime("%Y-%m-%dT%H:%M:%S")
  end

  # ナビゲーション用（アクティブ強調＋ARIA）
  def nav_link_to(name, path, active_match: nil, **opts)
    href = url_for(path)

    active =
      if active_match
        request.path.match?(active_match)
      else
        # current_page? は完全一致、start_with? は配下URLも拾う
        current_page?(href) || request.path.start_with?(URI(href).path)
      end

    base    = "text-sm md:text-base font-medium transition"
    states  = active ? "text-white underline" : "text-white/95 hover:text-white hover:underline"
    classes = [ base, states, opts.delete(:class) ].compact.join(" ")

    link_to name, href, { class: classes, "aria-current": (active ? "page" : nil) }.merge(opts)
  end

  # 秒 → "X時間Y分"（Y=0なら省略）。nilなら "−"
  def human_duration(seconds, blank: "-")
    return blank if seconds.nil?

    total = seconds.to_i.abs
    h = total / 3600
    m = (total % 3600) / 60

    if h.positive? && m.positive?
      "#{h}時間#{m}分"
    elsif h.positive?
      "#{h}時間"
    else
      "#{m}分"
    end
  end

  # 結果バッジ（達成/失敗/進行中）
  def result_badge(record)
    label, palette =
      if record.end_time.blank?
        ["進行中", "bg-amber-100 text-amber-800 ring-amber-200"]
      elsif record.success == true
        ["達成", "bg-emerald-100 text-emerald-800 ring-emerald-200"]
      elsif record.success == false
        ["失敗", "bg-rose-100 text-rose-800 ring-rose-200"]
      else
        ["-", "bg-gray-100 text-gray-700 ring-gray-200"]
      end

    content_tag(
      :span,
      label,
      class: "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-semibold ring-1 #{palette}"
    )
  end

  # 必要最低限のHeroicons相当（インラインSVG）
  def heroicon(name, classes: "w-5 h-5")
    svg =
      case name
      when :pencil
        # Pencil-square風
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M21 7.5L16.5 3 6 13.5V18h4.5L21 7.5z"/><path d="M3 21h18v-2H3v2z"/></svg>'
      when :trash
        # Trash風
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M9 3h6l1 2h4v2H3V5h4l1-2z"/><path d="M6 8h12l-1 12H7L6 8z"/></svg>'
      when :clock
        # Clock風（stroke）
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 3"/></svg>'
      else
        ""
      end

    content_tag(:span, svg.html_safe, class: classes)
  end
end
