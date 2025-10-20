# frozen_string_literal: true

Devise.setup do |config|
  #== Mailer
  config.mailer_sender = ENV.fetch("DEFAULT_MAIL_FROM", "no-reply@example.com")
  # config.mailer = 'Devise::Mailer'
  # config.parent_mailer = 'ActionMailer::Base'

  #== ORM
  require "devise/orm/active_record"

  #== Authentication keys
  # 既定: email を小文字化＆前後空白を除去
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]

  #== Session / Security
  config.skip_session_storage = [ :http_auth ]
  # CSRFトークンを認証時にリセット（既定trueのまま）
  # config.clean_up_csrf_token_on_authentication = true

  #== Password hashing
  config.stretches = Rails.env.test? ? 1 : 12
  # config.pepper = '...'

  #== Confirmable（使っていなければ無視されます）
  config.reconfirmable = true
  # config.allow_unconfirmed_access_for = 0.days
  # config.confirm_within = nil

  #== Rememberable
  # config.remember_for = 2.weeks
  config.expire_all_remember_me_on_sign_out = true

  #== Validatable
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  #== Timeoutable / Lockable（必要時に有効化）
  # config.timeout_in = 30.minutes
  # config.lock_strategy = :failed_attempts
  # config.unlock_strategy = :both
  # config.maximum_attempts = 20
  # config.unlock_in = 1.hour

  #== Recoverable
  # config.reset_password_keys = [:email]
  config.reset_password_within = 6.hours
  # config.sign_in_after_reset_password = true

  #== Scoped views（★重要：users/* ビューを使う）
  config.scoped_views = true

  #== Default scope
  # config.default_scope = :user

  #== Sign out
  config.sign_out_via = :delete

  #== Hotwire / Turbo（Rails 7系推奨設定）
  config.responder.error_status   = :unprocessable_entity
  config.responder.redirect_status = :see_other
  config.navigational_formats = [ "*/*", :html, :turbo_stream ]

  #== OmniAuth（必要なら有効化）
  # config.omniauth :github, ENV['GITHUB_ID'], ENV['GITHUB_SECRET'], scope: 'user:email'
end
