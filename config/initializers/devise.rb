# frozen_string_literal: true

Devise.setup do |config|
  # == Mailer
  config.mailer_sender = ENV.fetch("DEFAULT_MAIL_FROM", "no-reply@example.com")

  # == ORM
  require "devise/orm/active_record"

  # == Authentication keys
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]

  # == Session / Security
  config.skip_session_storage = [ :http_auth ]

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

  # == Scoped views（users/* ビューを使う）
  config.scoped_views = true

  # == Sign out
  config.sign_out_via = :delete

  # == Hotwire / Turbo
  config.responder.error_status    = :unprocessable_entity
  config.responder.redirect_status = :see_other
  config.navigational_formats      = [ "*/*", :html, :turbo_stream ]

  # ====================== OmniAuth（Google） ======================
  # Google Cloud Console の「承認済みのリダイレクトURI」には
  #   - http://localhost:3000/users/auth/google_oauth2/callback（開発）
  #   - https://fasty-web.onrender.com/users/auth/google_oauth2/callback（本番）
  # を完全一致で登録すること。
  #
  # 無条件でプロバイダを登録（ENVが空だと実認可は失敗するが、未登録404を防ぐ）
  config.omniauth :google_oauth2,
                  ENV["GOOGLE_CLIENT_ID"],
                  ENV["GOOGLE_CLIENT_SECRET"],
                  scope:       "email,profile",
                  prompt:      "select_account",
                  access_type: "offline",
                  client_options: {
                    authorize_url: "https://accounts.google.com/o/oauth2/v2/auth",
                    token_url:     "https://oauth2.googleapis.com/token"
                  }

  # 逆プロキシ(Render/Cloudflare)配下でも正しいコールバックURLを組み立てる
  OmniAuth.config.full_host = lambda do |env|
    scheme = (env["HTTP_X_FORWARDED_PROTO"] || env["rack.url_scheme"])
    host   = (env["HTTP_X_FORWARDED_HOST"]  || env["HTTP_HOST"])
    "#{scheme}://#{host}"
  end

  # OmniAuth v2：リクエストはPOSTのみ許可（GETは警告＆拒否）
  OmniAuth.config.allowed_request_methods = [ :post ]
  OmniAuth.config.logger = Rails.logger
  # ==============================================================
end
