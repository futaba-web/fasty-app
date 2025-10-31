# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # /users/auth/google_oauth2/callback
  def google_oauth2
    auth = request.env["omniauth.auth"]
    unless auth
      Rails.logger.error("[OmniAuth] auth hash is nil")
      set_flash_message!(:alert, :failure, kind: "Google", reason: "認証情報を取得できませんでした")
      return redirect_to new_user_session_path
    end

    begin
      @user = User.from_google(auth) # user.rbでalias済み（from_omniauthでもOK）
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[OmniAuth] save failed: #{e.record.errors.full_messages.join(', ')}")
      set_flash_message!(:alert, :failure, kind: "Google", reason: "ユーザーを作成・更新できませんでした")
      return redirect_to new_user_session_path
    rescue StandardError => e
      Rails.logger.error("[OmniAuth] exception: #{e.class} #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      set_flash_message!(:alert, :failure, kind: "Google", reason: "内部エラーが発生しました")
      return redirect_to new_user_session_path
    end

    if @user.persisted?
      set_flash_message!(:notice, :success, kind: "Google")
      sign_in_and_redirect @user, event: :authentication
    else
      Rails.logger.error("[OmniAuth] user not persisted")
      session["devise.google_data"] = auth.except("extra")
      set_flash_message!(:alert, :failure, kind: "Google", reason: "もう一度お試しください")
      redirect_to new_user_session_path
    end
  end

  # /users/auth/failure
  def failure
    err      = request.env["omniauth.error"]
    strategy = request.env["omniauth.error.strategy"]&.name
    type     = request.env["omniauth.error.type"]
    # Googleからは message/error/error_description 等が来ることがある
    reason   = params[:error_description] || params[:error_reason] || params[:error] || params[:message]

    Rails.logger.error <<~LOG
      [OmniAuth][failure]
        strategy=#{strategy.inspect}
        type=#{type.inspect}
        reason=#{reason.inspect}
        error_class=#{err&.class}
        error_message=#{err&.message}
    LOG

    msg = reason.presence || (type && type.to_s.humanize) || "Googleログインがキャンセルされました。"
    set_flash_message!(:alert, :failure, kind: "Google", reason: msg)
    redirect_to new_user_session_path
  end

  protected

  def after_omniauth_failure_path_for(_scope)
    new_user_session_path
  end
end
