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
end
