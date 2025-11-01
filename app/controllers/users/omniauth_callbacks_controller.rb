# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    state = params[:state].to_s
    code  = params[:code].to_s
    state_key = "oauth:google:state:#{state}:ok"
    code_key  = "oauth:google:code:#{code}:ok"

    # すでにOK印がある＝重複到達。ユーザーIDが取れれば sign_in して通す
    if (uid = (Rails.cache.read(state_key) || Rails.cache.read(code_key)))
      Rails.logger.info("[OmniAuth] duplicate callback (cache hit), signin user_id=#{uid}")
      user = User.find_by(id: uid)
      sign_in(user) if user && !user_signed_in?
      return redirect_to(after_sign_in_path_for(current_user || user || :user))
    end

    auth = request.env["omniauth.auth"]
    if auth&.info&.email.blank?
      Rails.logger.error("[OmniAuth] email missing in auth.info")
      set_flash_message!(:alert, :failure, kind: "Google", reason: "メールアドレスの取得に失敗しました")
      return redirect_to new_user_session_path
    end

    begin
      @user = User.from_google(auth)
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
      # 成功印として user_id を保存（2分で失効）
      Rails.cache.write(state_key, @user.id, expires_in: 2.minutes)
      Rails.cache.write(code_key,  @user.id, expires_in: 2.minutes)

      set_flash_message!(:notice, :success, kind: "Google")
      sign_in_and_redirect @user, event: :authentication
    else
      Rails.logger.error("[OmniAuth] user not persisted")
      session["devise.google_data"] = auth.except("extra")
      set_flash_message!(:alert, :failure, kind: "Google", reason: "もう一度お試しください")
      redirect_to new_user_session_path
    end
  end

  def failure
    state = params[:state].to_s
    code  = params[:code].to_s
    state_key = "oauth:google:state:#{state}:ok"
    code_key  = "oauth:google:code:#{code}:ok"

    # 1回目成功済みなら user_id を取り出して sign_in して通す
    if user_signed_in? || (uid = (Rails.cache.read(state_key) || Rails.cache.read(code_key)))
      user = current_user || User.find_by(id: uid)
      Rails.logger.info("[OmniAuth][failure] treated as success; sign_in user_id=#{user&.id}")
      sign_in(user) if user && !user_signed_in?
      return redirect_to(after_sign_in_path_for(user || current_user || :user))
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
