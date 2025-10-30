# frozen_string_literal: true

Devise.setup do |config|
  # == Mailer
  config.mailer_sender = ENV.fetch("DEFAULT_MAIL_FROM", "no-reply@example.com")
  # config.mailer = 'Devise::Mailer'
  # config.parent_mailer = 'ActionMailer::Base'

  # == ORM
  require "devise/orm/active_record"

  # == Authentication keys
  config.case_insensitive_keys  = [ :email ]
  config.strip_whitespace_keys  = [ :email ]

  # == Session / Security
  config.skip_session_storage = [ :http_auth ]
  # config.clean_up_csrf_token_on_authentication = true

  # == Password hashing
  config.stretches = Rails.env.test? ? 1 : 12
  # config.pepper = '...'

  # == Confirmable
  config.reconfirmable = true

  # == Rememberable
  # config.remember_for = 2.weeks
  config.expire_all_remember_me_on_sign_out = true

  # == Validatable
  config.password_length = 6..128
  config.email_regexp    = /\A[^@\s]+@[^@\s]+\z/

  # == Timeoutable / Lockable（必要なら有効化）
  # config.timeout_in       = 30.minutes
  # config.lock_strategy    = :failed_attempts
  # config.unlock_strategy  = :both
  # config.maximum_attempts = 20
  # config.unlock_in        = 1.hour

  # == Recoverable
  # config.reset_password_keys = [:email]
  config.reset_password_within = 6.hours
  # config.sign_in_after_reset_password = true

  # == Scoped views（users/* ビューを使う）
  config.scoped_views = true

  # == Default scope
  # config.default_scope = :user

  # == Sign out
  config.sign_out_via = :delete

  # == Hotwire / Turbo
  config.responder.error_status    = :unprocessable_entity
  config.responder.redirect_status = :see_other
  config.navigational_formats      = [ "*/*", :html, :turbo_stream ]

  # == OmniAuth（Google）
  #
  # Google Cloud Console の「承認済みのリダイレクト URI」には
  #   http://localhost:3000/users/auth/google_oauth2/callback
  # を（本番は本番URLで）**完全一致**で登録してください。
  #
  google_id     = ENV["GOOGLE_CLIENT_ID"]
  google_secret = ENV["GOOGLE_CLIENT_SECRET"]

  if google_id.present? && google_secret.present?
    config.omniauth :google_oauth2,
                    google_id,
                    google_secret,
                    {
                      scope:       "openid email profile",
                      prompt:      "select_account",
                      access_type: "offline",
                      # ▼ 重要：v2 エンドポイントを明示（旧URLだと 404 になるケース対策）
                      client_options: {
                        authorize_url: "https://accounts.google.com/o/oauth2/v2/auth",
                        token_url:     "https://oauth2.googleapis.com/token"
                      }
                    }
  else
    Rails.logger.warn("[Devise/OmniAuth] GOOGLE_CLIENT_ID/SECRET が未設定のため、Googleプロバイダは無効です。")
  end

  # --- 開発時のデバッグ（任意）---
  if Rails.env.development?
    require "omniauth"
    OmniAuth.config.allowed_request_methods = %i[post get]
    OmniAuth.config.silence_get_warning     = true
  end
end
