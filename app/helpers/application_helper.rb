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

  def nav_link_to(name, path, active_match: nil, **opts)
    # pathはhelperでも文字列でもOK
    href = url_for(path)

    active =
      if active_match
        request.path.match?(active_match)
      else
        # current_page? は完全一致、start_with? は配下URLも拾う
        current_page?(href) || request.path.start_with?(URI(href).path)
      end

    base   = "text-sm md:text-base font-medium transition"
    states = active ? "text-white underline" : "text-white/95 hover:text-white hover:underline"
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
end
