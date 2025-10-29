# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # /users/auth/google_oauth2/callback
  def google_oauth2
    auth = request.env["omniauth.auth"]
    @user = User.from_omniauth(auth)

    if @user.persisted?
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.google_data"] = auth.except("extra")
      redirect_to new_user_registration_url,
                  alert: @user.errors.full_messages.join("\n")
    end
  end

  def failure
    redirect_to new_user_session_path,
                alert: "Googleログインに失敗しました。もう一度お試しください。"
  end
end
