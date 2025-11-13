# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # OmniAuth コールバックは omniauth-rails_csrf_protection の state で守られているので、
  # Rails の authenticity_token チェックは外す
  skip_before_action :verify_authenticity_token, only: %i[google_oauth2 line failure]

  # ==================== Entry points ====================

  # /users/auth/google_oauth2/callback
  def google_oauth2
    handle_oauth("google_oauth2")
  end

  # /users/auth/line/callback
  def line
    handle_oauth("line")
  end

  # ==================== 共通 failure ====================

  # /users/auth/failure
  def failure
    # 既にログインしていれば即抜け（重複到達のノイズ削減）
    return redirect_to(after_sign_in_path_for(current_user)) if user_signed_in?

    provider_key = request.env["omniauth.error.strategy"]&.name.to_s.presence || "unknown"
    state        = params[:state].to_s
    code         = params[:code].to_s

    state_key = cache_key(provider_key, "state", state)
    code_key  = cache_key(provider_key, "code",  code)

    # 1回目成功済みなら user_id を取り出して sign_in して通す
    if (uid = read_dup_uid(state_key, code_key))
      user = User.find_by(id: uid)
      Rails.logger.info("[OmniAuth][failure->success] dup ignored; provider=#{provider_key} user_id=#{user&.id} state_tail=#{state.last(6)}")
      sign_in(user) if user && !user_signed_in?
      return redirect_to(after_sign_in_path_for(user || :user))
    end

    err    = request.env["omniauth.error"]
    type   = request.env["omniauth.error.type"]
    reason = params[:error_description] || params[:error_reason] || params[:error] || params[:message]

    Rails.logger.error <<~LOG
      [OmniAuth][failure]
        provider=#{provider_key.inspect}
        type=#{type.inspect}
        reason=#{reason.inspect}
        error_class=#{err&.class}
        error_message=#{err&.message}
        state_tail=#{state.last(6)}
    LOG

    human_kind = provider_label(provider_key)

    user_msg =
      case type.to_s
      when "access_denied"
        "#{human_kind}ログインがキャンセルされました。"
      when "invalid_credentials", "invalid_grant", "invalid_request"
        "もう一度お試しください。"
      else
        "ログインに失敗しました。しばらくしてから再度お試しください。"
      end

    set_flash_message!(
      :alert,
      :failure,
      kind:   human_kind,
      reason: (user_msg || "もう一度お試しください。")
    )
    redirect_to new_user_session_path
  end

  # ==================== Devise hooks ====================

  protected

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || mypage_path
  end

  def after_omniauth_failure_path_for(_scope)
    new_user_session_path
  end

  # ==================== 共通処理 ====================

  private

  # Google / LINE どちらからも呼ぶ共通ロジック
  def handle_oauth(provider_key)
    # すでにログイン済みなら、コールバック処理を全スキップして即リダイレクト
    return redirect_to(after_sign_in_path_for(current_user)) if user_signed_in?

    state = params[:state].to_s
    code  = params[:code].to_s

    state_key = cache_key(provider_key, "state", state)
    code_key  = cache_key(provider_key, "code",  code)

    # すでにOK印がある＝重複到達。ユーザーIDが取れれば sign_in して通す
    if (uid = read_dup_uid(state_key, code_key))
      Rails.logger.info("[OmniAuth] duplicate callback; provider=#{provider_key} signin user_id=#{uid} state_tail=#{state.last(6)}")
      user = User.find_by(id: uid)
      sign_in(user) if user && !user_signed_in?
      return redirect_to(after_sign_in_path_for(current_user || user || :user))
    end

    auth = request.env["omniauth.auth"]
    unless auth
      Rails.logger.error("[OmniAuth] auth hash is nil (provider=#{provider_key} state_tail=#{state.last(6)})")
      set_flash_message!(
        :alert,
        :failure,
        kind:   provider_label(provider_key),
        reason: "認証情報を取得できませんでした"
      )
      return redirect_to new_user_session_path
    end

    # Google 系だけは email 必須（LINE は email 無し運用も許容）
    if provider_key.to_s.start_with?("google") && auth.info&.email.blank?
      Rails.logger.error("[OmniAuth] email missing in auth.info (provider=#{provider_key} state_tail=#{state.last(6)})")
      set_flash_message!(
        :alert,
        :failure,
        kind:   "Google",
        reason: "メールアドレスの取得に失敗しました"
      )
      return redirect_to new_user_session_path
    end

    begin
      # Google / LINE 共通の from_omniauth
      @user = User.from_omniauth(auth)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[OmniAuth] save failed (provider=#{provider_key}): #{e.record.errors.full_messages.join(', ')}")
      set_flash_message!(
        :alert,
        :failure,
        kind:   provider_label(provider_key),
        reason: "ユーザーを作成・更新できませんでした"
      )
      return redirect_to new_user_session_path
    rescue StandardError => e
      Rails.logger.error("[OmniAuth] exception (provider=#{provider_key}): #{e.class} #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      set_flash_message!(
        :alert,
        :failure,
        kind:   provider_label(provider_key),
        reason: "内部エラーが発生しました"
      )
      return redirect_to new_user_session_path
    end

    if @user.persisted?
      # 成功印として user_id を保存（2分で失効）
      write_dup_uid(state_key, @user.id)
      write_dup_uid(code_key,  @user.id)

      set_flash_message!(:notice, :success, kind: provider_label(provider_key))
      sign_in_and_redirect @user, event: :authentication
    else
      Rails.logger.error("[OmniAuth] user not persisted (provider=#{provider_key})")
      session["devise.oauth_data"] = auth.except("extra")
      set_flash_message!(
        :alert,
        :failure,
        kind:   provider_label(provider_key),
        reason: "もう一度お試しください"
      )
      redirect_to new_user_session_path
    end
  end

  # "Google" / "LINE" / "SNS" など画面に出す名前
  def provider_label(provider_key)
    case provider_key.to_s
    when "google", "google_oauth2"
      "Google"
    when "line"
      "LINE"
    else
      "SNS"
    end
  end

  # state/code からキャッシュキー生成
  # 例: "oauth:line:state:xxxx:ok"
  def cache_key(provider_key, kind, token)
    return nil if token.blank?

    "oauth:#{provider_key}:#{kind}:#{token}:ok"
  end

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
