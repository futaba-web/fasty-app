# frozen_string_literal: true

Devise.setup do |config|
  # Mailer
  config.mailer_sender = ENV.fetch("DEFAULT_MAIL_FROM", "no-reply@example.com")

  # ORM
  require "devise/orm/active_record"

  # Auth keys
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]

  # Session / Security
  config.skip_session_storage = [ :http_auth ]

  # Password hashing
  config.stretches = Rails.env.test? ? 1 : 12

  # Confirmable
  config.reconfirmable = true

  # Rememberable
  config.expire_all_remember_me_on_sign_out = true

  # Validatable
  config.password_length = 6..128
  config.email_regexp    = /\A[^@\s]+@[^@\s]+\z/

  # Recoverable
  config.reset_password_within = 6.hours

  # Scoped views
  config.scoped_views = true

  # Sign out
  config.sign_out_via = :delete

  # Hotwire / Turbo
  config.responder.error_status    = :unprocessable_entity
  config.responder.redirect_status = :see_other
  config.navigational_formats      = [ "*/*", :html, :turbo_stream ]

  # ===================== OmniAuth（Google） =====================
  # GCP 側の「承認済みのリダイレクトURI」に *完全一致* で下記を登録しておくこと
  # - http://localhost:3000/users/auth/google_oauth2/callback   （開発）
  # - https://<本番ドメイン>/users/auth/google_oauth2/callback  （本番）
  require "omniauth-google-oauth2"

  google_id     = ENV["GOOGLE_CLIENT_ID"]
  google_secret = ENV["GOOGLE_CLIENT_SECRET"]

  config.omniauth :google_oauth2,
                  google_id,
                  google_secret,
                  {
                    scope:       "openid,email,profile",
                    prompt:      "select_account",     # ← Googleの画面でアカウント選択
                    access_type: "online",
                    # 重要：redirect_uri は **指定しない**（環境依存のズレを防ぐ）
                    client_options: {
                      authorize_url: "https://accounts.google.com/o/oauth2/v2/auth",
                      token_url:     "https://oauth2.googleapis.com/token"
                    }
                  }
  # =============================================================
end

# ===== OmniAuth のホスト判定（逆プロキシ対策 & 本番固定オプション）=====
require "omniauth"

# APP_HOST があればそれを最優先で利用（例: https://fasty-web.onrender.com）
OmniAuth.config.full_host = lambda do |env|
  if ENV["APP_HOST"].present?
    ENV["APP_HOST"]
  else
    scheme = env["HTTP_X_FORWARDED_PROTO"] || env["rack.url_scheme"] || "https"
    host   = env["HTTP_X_FORWARDED_HOST"]  || env["HTTP_HOST"]
    "#{scheme}://#{host}"
  end
end

# OmniAuth v2 で GET を許容（直リンクや戻る等での失敗を避ける）
OmniAuth.config.allowed_request_methods = %i[post get]
OmniAuth.config.silence_get_warning     = true

# ロガー
OmniAuth.config.logger = Rails.logger
