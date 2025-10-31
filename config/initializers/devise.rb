# frozen_string_literal: true

Devise.setup do |config|
  # == Mailer
  config.mailer_sender = ENV.fetch("DEFAULT_MAIL_FROM", "no-reply@example.com")

  # == ORM
  require "devise/orm/active_record"

  # == Authentication keys
  config.case_insensitive_keys   = [ :email ]
  config.strip_whitespace_keys   = [ :email ]

  # == Session / Security
  config.skip_session_storage    = [ :http_auth ]

  # == Password hashing
  config.stretches               = Rails.env.test? ? 1 : 12

  # == Confirmable
  config.reconfirmable           = true

  # == Rememberable
  config.expire_all_remember_me_on_sign_out = true

  # == Validatable
  config.password_length         = 6..128
  config.email_regexp            = /\A[^@\s]+@[^@\s]+\z/

  # == Recoverable
  config.reset_password_within   = 6.hours

  # == Scoped views（users/* ビューを使う）
  config.scoped_views            = true

  # == Sign out
  config.sign_out_via            = :delete

  # == Hotwire / Turbo
  config.responder.error_status    = :unprocessable_entity
  config.responder.redirect_status = :see_other
  config.navigational_formats      = [ "*/*", :html, :turbo_stream ]

  # ======================== OmniAuth（Google） ========================
  # GCPの「承認済みのリダイレクトURI」に *完全一致* で以下を登録しておくこと
  #   - http://localhost:3000/users/auth/google_oauth2/callback（開発）
  #   - https://<本番ドメイン>/users/auth/google_oauth2/callback（本番）
  require "omniauth-google-oauth2"

  google_id     = ENV["GOOGLE_CLIENT_ID"]
  google_secret = ENV["GOOGLE_CLIENT_SECRET"]

  # setup: ブロックで毎リクエスト最終上書き（prompt=none等の外部上書きを無効化）
  config.omniauth(
    :google_oauth2,
    google_id,
    google_secret,
    scope:        "openid email profile",
    access_type:  "online",
    prompt:       "select_account",
    client_options: {
      authorize_url: "https://accounts.google.com/o/oauth2/v2/auth",
      token_url:     "https://oauth2.googleapis.com/token"
    },
    setup: lambda { |env|
      s = env["omniauth.strategy"]

      # host 決定（ENV優先 → 逆プロキシヘッダ → rack.url_scheme/HTTP_HOST）
      app_host =
        if ENV["APP_HOST"].present?
          ENV["APP_HOST"]
        else
          scheme = env["HTTP_X_FORWARDED_PROTO"] || env["rack.url_scheme"] || "https"
          host   = env["HTTP_X_FORWARDED_HOST"]  || env["HTTP_HOST"]
          "#{scheme}://#{host}"
        end

      # 認証時に毎回“正しい”値を強制
      s.options[:scope]        = "openid email profile"
      s.options[:prompt]       = "select_account"
      s.options[:redirect_uri] = "#{app_host}/users/auth/google_oauth2/callback"
    }
  )
  # ===================================================================
end

# ===== OmniAuth の共通設定（逆プロキシ配下のホスト判断を安定させる） =====
require "omniauth"

OmniAuth.config.full_host = lambda do |env|
  if ENV["APP_HOST"].present?
    ENV["APP_HOST"]
  else
    scheme = env["HTTP_X_FORWARDED_PROTO"] || env["rack.url_scheme"] || "https"
    host   = env["HTTP_X_FORWARDED_HOST"]  || env["HTTP_HOST"]
    "#{scheme}://#{host}"
  end
end

# OmniAuth v2: GET も許容（リンク直叩き対策）
OmniAuth.config.allowed_request_methods = %i[post get]
OmniAuth.config.silence_get_warning     = true

# ログは Rails.logger へ
OmniAuth.config.logger = Rails.logger
