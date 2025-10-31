# config/environments/production.rb
require "active_support/core_ext/integer/time"
require "uri"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available.
  # config.require_master_key = true

  # Serve static files when Render sets RAILS_SERVE_STATIC_FILES=1
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Assets
  config.assets.css_compressor = nil
  config.assets.compile = false

  # --- Host/URL settings (Render) -----------------------------------------
  # APP_HOST はフルURL想定（例: https://fasty-web.onrender.com）
  app_origin = ENV.fetch("APP_HOST", "https://fasty-web.onrender.com")
  u = URI(app_origin)
  host_only = [ u.host, (u.port && ![ 80, 443 ].include?(u.port)) ? u.port : nil ].compact.join(":")

  # url_for / *_url
  Rails.application.routes.default_url_options[:host]     = host_only
  Rails.application.routes.default_url_options[:protocol] = u.scheme || "https"

  # アセットURL（image_url など）
  config.asset_host = app_origin

  # メール用
  config.action_mailer.default_url_options = { host: host_only, protocol: u.scheme || "https" }
  # ------------------------------------------------------------------------

  # Files
  config.active_storage.service = :local

  # SSL
  config.assume_ssl = true
  config.force_ssl  = true
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Logging
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  config.log_tags  = [ :request_id ]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Mailer
  config.action_mailer.perform_caching = false
  # config.action_mailer.raise_delivery_errors = false

  # I18n
  config.i18n.fallbacks = true

  # Deprecations
  config.active_support.report_deprecations = false

  # DB
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]

  # Host protection (必要なら有効化)
  # config.hosts = [host_only, /.*\.onrender\.com/]
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
