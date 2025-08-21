module ApplicationHelper
    def display_name(user)
      return "" unless user
      user.name.present? ? user.name : user.email.to_s.split("@").first
    end

    def home_path
        user_signed_in? ? authenticated_root_path : unauthenticated_root_path
    end
end
