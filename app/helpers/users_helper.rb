# app/helpers/users_helper.rb
module UsersHelper
  def display_name(user)
    return "ゲスト" unless user
    if user.respond_to?(:name) && user.name.present?
      user.name
    else
      user.email.to_s.split("@").first
    end
  end
end
