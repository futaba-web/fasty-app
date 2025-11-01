# frozen_string_literal: true

# NOTE: 逆プロキシ環境でも正しいホスト/スキームを解決
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
OmniAuth.config.allowed_request_methods = %i[post get]
OmniAuth.config.silence_get_warning     = true
OmniAuth.config.logger                  = Rails.logger

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
  # GCP: 承認済みのリダイレクトURIは完全一致で登録しておくこと
  # - http://localhost:3000/users/auth/google_oauth2/callback
  # - https://<本番ホスト>/users/auth/google_oauth2/callback
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
      client_options: {
        authorize_url: "https://accounts.google.com/o/oauth2/v2/auth",
        token_url:     "https://oauth2.googleapis.com/token"
      },
      # リクエストごとに base_url から callback を動的設定
      setup: lambda { |env|
        request = Rack::Request.new(env)
        callback = "#{request.base_url}/users/auth/google_oauth2/callback"

        strategy = env["omniauth.strategy"]

        # token 交換・認可の両方に確実に反映
        strategy.options[:redirect_uri] = callback

        strategy.options[:client_options]      ||= {}
        strategy.options[:client_options][:redirect_uri] = callback

        strategy.options[:authorize_params]    ||= {}
        strategy.options[:authorize_params][:redirect_uri] = callback
        strategy.options[:authorize_params][:scope]        = "openid email profile"
        strategy.options[:authorize_params][:access_type]  = "offline"
        strategy.options[:authorize_params][:prompt]       = "select_account consent"

        # 保険: 外部からの prompt=none を除去
        env["rack.request.query_hash"]&.delete("prompt")
        env["rack.request.form_hash"]&.delete("prompt")
      }
    }
  )
  # ===================================================================
end
