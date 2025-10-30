# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # /users/auth/google_oauth2/callback
  def google_oauth2
    auth = request.env["omniauth.auth"]

    unless auth
      Rails.logger.error("[OmniAuth] auth hash is nil")
      return redirect_to new_user_session_path,
                         alert: "Googleログインに失敗しました。（認証情報が取得できませんでした）"
    end

    @user = User.from_omniauth(auth)

    if @user.persisted?
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
      sign_in_and_redirect @user, event: :authentication
    else
      Rails.logger.error("[OmniAuth] user save failed: #{@user.errors.full_messages.join(', ')}")
      session["devise.google_data"] = auth.except("extra")
      redirect_to new_user_session_path,
                  alert: "Googleログインに失敗しました。もう一度お試しください。"
    end
  rescue StandardError => e
    backtrace = (e.backtrace || []).first(5).join("\n")
    msg = "[OmniAuth] exception: #{e.class} #{e.message}\n#{backtrace}"
    Rails.logger.error(msg)

    redirect_to new_user_session_path,
                alert: "Googleログインに失敗しました。時間をおいて再度お試しください。"
  end

  # /users/auth/failure
  def failure
  err      = request.env["omniauth.error"]
  strategy = request.env["omniauth.error.strategy"]&.name
  type     = request.env["omniauth.error.type"]
  reason   = params[:error_description] || params[:error_reason] || params[:error]

  Rails.logger.error <<~LOG
    [OmniAuth][failure]
      strategy=#{strategy.inspect}
      type=#{type.inspect}
      reason=#{reason.inspect}
      error_class=#{err&.class}
      error_message=#{err&.message}
  LOG

  # デバッグ中はユーザーにも理由を軽く見せる（後で消す）
  flash_alert = reason.presence || (type && type.to_s.humanize) || "Googleログインがキャンセルされました。"
  redirect_to new_user_session_path, alert: flash_alert
end


  protected

  def after_omniauth_failure_path_for(_scope)
    new_user_session_path
  end
end
