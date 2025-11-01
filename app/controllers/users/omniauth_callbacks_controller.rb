# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # /users/auth/google_oauth2/callback
  def google_oauth2
    # ---- duplicate guard (idempotency) -------------------------------
    st = params[:state].to_s
    if session[:handled_oauth_state] == st
      Rails.logger.info("[OmniAuth] duplicate callback detected (state=#{st}), skipping")
      return redirect_to(after_sign_in_path_for(current_user || :user))
    end
    session[:handled_oauth_state] = st
    # ------------------------------------------------------------------

    auth = request.env["omniauth.auth"]
    if auth&.info&.email.blank?
      Rails.logger.error("[OmniAuth] email missing in auth.info")
      set_flash_message!(:alert, :failure, kind: "Google", reason: "メールアドレスの取得に失敗しました")
      return redirect_to new_user_session_path
    end

    begin
      @user = User.from_google(auth) # 既存の取込メソッド名に合わせて
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
    # 1回目が成功済みで、二重コールバックの2回目が失敗しただけなら成功扱いで通す
    if user_signed_in?
      Rails.logger.info("[OmniAuth][failure] user already signed in; treat as success")
      return redirect_to(after_sign_in_path_for(current_user))
    end

    err      = request.env["omniauth.error"]
    strategy = request.env["omniauth.error.strategy"]&.name
    type     = request.env["omniauth.error.type"]
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

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || mypage_path
  end

  def after_omniauth_failure_path_for(_scope)
    new_user_session_path
  end
end
