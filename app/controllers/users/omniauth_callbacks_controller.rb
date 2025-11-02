# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # /users/auth/google_oauth2/callback
  def google_oauth2
    state = params[:state].to_s
    code  = params[:code].to_s

    state_key = state.present? ? "oauth:google:state:#{state}:ok" : nil
    code_key  = code.present?  ? "oauth:google:code:#{code}:ok"   : nil

    # すでにOK印がある＝重複到達。ユーザーIDが取れれば sign_in して通す
    if (uid = read_dup_uid(state_key, code_key))
      Rails.logger.info("[OmniAuth] duplicate callback; signin user_id=#{uid} state_tail=#{state.last(6)}")
      user = User.find_by(id: uid)
      sign_in(user) if user && !user_signed_in?
      return redirect_to(after_sign_in_path_for(current_user || user || :user))
    end

    auth = request.env["omniauth.auth"]
    unless auth
      Rails.logger.error("[OmniAuth] auth hash is nil (state_tail=#{state.last(6)})")
      set_flash_message!(:alert, :failure, kind: "Google", reason: "認証情報を取得できませんでした")
      return redirect_to new_user_session_path
    end

    if auth.info&.email.blank?
      Rails.logger.error("[OmniAuth] email missing in auth.info (state_tail=#{state.last(6)})")
      set_flash_message!(:alert, :failure, kind: "Google", reason: "メールアドレスの取得に失敗しました")
      return redirect_to new_user_session_path
    end

    begin
      @user = User.from_google(auth) # ※ User.from_google は既存の実装を利用
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
      write_dup_uid(state_key, @user.id)
      write_dup_uid(code_key,  @user.id)

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
    state = params[:state].to_s
    code  = params[:code].to_s
    state_key = state.present? ? "oauth:google:state:#{state}:ok" : nil
    code_key  = code.present?  ? "oauth:google:code:#{code}:ok"   : nil

    # 1回目成功済みなら user_id を取り出して sign_in して通す
    if user_signed_in? || (uid = read_dup_uid(state_key, code_key))
      user = current_user || User.find_by(id: uid)
      Rails.logger.info("[OmniAuth][failure->success] dup ignored; user_id=#{user&.id} state_tail=#{state.last(6)}")
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
        state_tail=#{state.last(6)}
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

  private

  # 重複検出: state/code のどちらかでヒットした user_id を返す
  def read_dup_uid(state_key, code_key)
    Rails.cache.read(state_key) || Rails.cache.read(code_key)
  end

  # 成功印の保存（key が nil/blank のときは何もしない）
  def write_dup_uid(key, uid)
    return if key.blank?
    Rails.cache.write(key, uid, expires_in: 2.minutes)
  end
end
