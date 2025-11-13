# frozen_string_literal: true

# NOTE: 逆プロキシ環境でも正しいホスト/スキームを解決
require "omniauth"

OmniAuth.config.full_host = lambda do |env|
  # 本番のみ APP_HOST を優先（ローカルでの redirect_uri 不一致を避ける）
  if Rails.env.production? && ENV["APP_HOST"].present?
    ENV["APP_HOST"]
  else
    scheme = env["HTTP_X_FORWARDED_PROTO"] || env["rack.url_scheme"] || "https"
    host   = env["HTTP_X_FORWARDED_HOST"]  || env["HTTP_HOST"]
    "#{scheme}://#{host}"
  end
end

# 開始エンドポイントは POST のみに限定（リンクプレビュー等の誤発火を抑止）
OmniAuth.config.allowed_request_methods = %i[post]
OmniAuth.config.silence_get_warning     = true
OmniAuth.config.logger                  = Rails.logger

Devise.setup do |config|
  # == Mailer
  config.mailer_sender = ENV.fetch("DEFAULT_MAIL_FROM", "no-reply@example.com")

  # == ORM
  require "devise/orm/active_record"

  # == Authentication keys
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  # == Session / Security
  config.skip_session_storage = [:http_auth]

  # == Password hashing
  config.stretches = Rails.env.test? ? 1 : 12

  # == Confirmable
  config.reconfirmable = true

  # == Rememberable
  config.expire_all_remember_me_on_sign_out = true

  # == Validatable
  config.password_length = 6..128
  config.email_regexp    = /\A[^@\s]+@[^@\s]+\z/

  # == Recoverable
  config.reset_password_within = 6.hours

  # == Scoped views
  config.scoped_views = true

  # == Sign out
  config.sign_out_via = :delete

  # == Hotwire / Turbo
  config.responder.error_status    = :unprocessable_entity
  config.responder.redirect_status = :see_other
  config.navigational_formats      = ["*/*", :html, :turbo_stream]

  # =====================================================
  # OmniAuth 用の共通ホスト
  # =====================================================
  app_host =
    if ENV["APP_HOST"].present?
      # APP_HOST があればそれを最優先（ngrok などでも使える）
      ENV["APP_HOST"]
    else
      Rails.env.production? ? "https://fasty-web.onrender.com" : "http://localhost:3000"
    end

  google_redirect_uri = "#{app_host}/users/auth/google_oauth2/callback"
  line_redirect_uri   = "#{app_host}/users/auth/line/callback"

  # ======================== OmniAuth（Google） ========================
  # GCP: 承認済みのリダイレクトURIは完全一致で登録しておくこと
  # - http://localhost:3000/users/auth/google_oauth2/callback
  # - https://fasty-web.onrender.com/users/auth/google_oauth2/callback
  require "omniauth-google-oauth2"

  google_id     = ENV.fetch("GOOGLE_CLIENT_ID")
  google_secret = ENV.fetch("GOOGLE_CLIENT_SECRET")

  config.omniauth(
    :google_oauth2,
    google_id,
    google_secret,
    {
      scope:        "openid email profile",
      access_type:  "offline",
      prompt:       "select_account consent", # ← none は使わない
      redirect_uri: google_redirect_uri
    }
  )
  # ===================================================================

  # ======================== OmniAuth（LINE） ==========================
  # LINE Login（チャネル ID / シークレット / コールバックURL は app_host から算出）
  require "omniauth-line"

  line_channel_id     = ENV.fetch("LINE_LOGIN_CHANNEL_ID", nil)
  line_channel_secret = ENV.fetch("LINE_LOGIN_CHANNEL_SECRET", nil)

  config.omniauth(
    :line,
    line_channel_id,
    line_channel_secret,
    {
      callback_url: line_redirect_uri,
      scope:        "profile openid",
      prompt:       "consent"
      # 必要に応じて bot_prompt などもここに追加可能
    }
  )
  # ===================================================================
end
