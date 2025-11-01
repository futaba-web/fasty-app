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

  # == Scoped views
  config.scoped_views            = true

  # == Sign out
  config.sign_out_via            = :delete

  # == Hotwire / Turbo
  config.responder.error_status    = :unprocessable_entity
  config.responder.redirect_status = :see_other
  config.navigational_formats      = [ "*/*", :html, :turbo_stream ]

  # ======================== OmniAuth（Google） ========================
  # GCP の「承認済みのリダイレクトURI」は完全一致で登録：
  # - http://localhost:3000/users/auth/google_oauth2/callback
  # - https://<本番ドメイン>/users/auth/google_oauth2/callback
  require "omniauth-google-oauth2"

  google_id     = ENV["GOOGLE_CLIENT_ID"]
  google_secret = ENV["GOOGLE_CLIENT_SECRET"]

  config.omniauth(
    :google_oauth2,
    google_id,
    google_secret,
    scope:        "openid email profile",
    access_type:  "offline",
    client_options: {
      authorize_url: "https://accounts.google.com/o/oauth2/v2/auth",
      token_url:     "https://oauth2.googleapis.com/token"
    },
    # ★毎リクエストで最終上書き（prompt=none を無効化・redirect_uri を固定）
    setup: lambda { |env|
      s = env["omniauth.strategy"]

      app_host =
        if ENV["APP_HOST"].present?
          ENV["APP_HOST"]
        else
          scheme = env["HTTP_X_FORWARDED_PROTO"] || env["rack.url_scheme"] || "https"
          host   = env["HTTP_X_FORWARDED_HOST"]  || env["HTTP_HOST"]
          "#{scheme}://#{host}"
        end

      redirect_uri = "#{app_host}/users/auth/google_oauth2/callback"

      # options にも、実際にURLへ載る authorize_params にも両方セット
      s.options[:redirect_uri] = redirect_uri
      s.options[:scope]        = "openid email profile"
      s.options[:access_type]  = "offline"

      s.options.authorize_params["prompt"]       = "select_account"
      s.options.authorize_params["redirect_uri"] = redirect_uri
      s.options.authorize_params["scope"]        = "openid email profile"
      s.options.authorize_params["access_type"]  = "offline"

      # 外部から混入した prompt を破棄（保険）
      env["rack.request.query_hash"]&.delete("prompt")
      env["rack.request.form_hash"]&.delete("prompt")
    }
  )
  # ===================================================================
end

# ===== OmniAuth 共通設定（逆プロキシ下のホスト解決を安定化） =====
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

# OmniAuth v2: GET も許容（直リンク対策）
OmniAuth.config.allowed_request_methods = %i[post get]
OmniAuth.config.silence_get_warning     = true

# ログ
OmniAuth.config.logger = Rails.logger
