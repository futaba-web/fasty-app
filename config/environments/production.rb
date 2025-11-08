# config/environments/production.rb
require "active_support/core_ext/integer/time"
require "uri"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # ------------------------------------------------------------------
  # Boot / Reload / Cache
  # ------------------------------------------------------------------
  # Code is not reloaded between requests.
  config.enable_reloading = false
  # Eager load code on boot.
  config.eager_load = true
  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available.
  # config.require_master_key = true

  # ------------------------------------------------------------------
  # Static files (Render sets RAILS_SERVE_STATIC_FILES=1)
  # ------------------------------------------------------------------
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # ------------------------------------------------------------------
  # Assets
  # ------------------------------------------------------------------
  config.assets.css_compressor = nil
  config.assets.compile = false

  # ------------------------------------------------------------------
  # Host / URL 基本設定
  # - APP_HOST は「フルURL」を想定（例: https://fasty-web.onrender.com）
  # - PRIMARY_HOST は正規ホスト（例: www.example.com）
  # - APEX_HOST は非正規ホスト（例: example.com）
  # ------------------------------------------------------------------
  app_origin    = ENV.fetch("APP_HOST", "https://fasty-web.onrender.com")
  primary_host  = ENV["PRIMARY_HOST"]
  apex_host     = ENV["APEX_HOST"]

  u = URI(app_origin)
  host_only = [
    u.host,
    (u.port && ![ 80, 443 ].include?(u.port)) ? u.port : nil
  ].compact.join(":")

  # url_for / *_url
  Rails.application.routes.default_url_options[:host]     = primary_host.presence || host_only
  Rails.application.routes.default_url_options[:protocol] = (u.scheme || "https")

  # アセットURL（CDN を使うならここを CDN のフルURLに）
  config.asset_host = app_origin

  # メール用
  config.action_mailer.default_url_options = {
    host:     primary_host.presence || host_only,
    protocol: (u.scheme || "https")
  }

  # ------------------------------------------------------------------
  # Active Storage
  # ------------------------------------------------------------------
  config.active_storage.service = :local

  # ------------------------------------------------------------------
  # SSL / HSTS / Host 制限
  # - Render などのリバースプロキシ配下を想定
  # - /health, /up はリダイレクト対象から除外（監視の安定化）
  # ------------------------------------------------------------------
  config.assume_ssl = true
  config.force_ssl  = (ENV["FORCE_SSL"] != "false")

  config.ssl_options = {
    hsts: { expires: 1.year, subdomains: true, preload: true },
    redirect: {
      exclude: ->(request) { [ "/health", "/up" ].include?(request.path) }
    }
  }

  # 許可ホスト（正規/非正規/Render）
  config.hosts << primary_host if primary_host.present?
  config.hosts << apex_host    if apex_host.present?
  config.hosts << /.*\.onrender\.com/

  # ------------------------------------------------------------------
  # Logging
  # ------------------------------------------------------------------
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  config.log_tags  = [ :request_id ]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # ------------------------------------------------------------------
  # Mailer
  # ------------------------------------------------------------------
  config.action_mailer.perform_caching = false
  # config.action_mailer.raise_delivery_errors = false

  # ------------------------------------------------------------------
  # I18n / Deprecation
  # ------------------------------------------------------------------
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false

  # ------------------------------------------------------------------
  # DB
  # ------------------------------------------------------------------
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]

  # ------------------------------------------------------------------
  # Host protection（必要に応じて）
  # ------------------------------------------------------------------
  # config.host_authorization = {
  #   exclude: ->(request) { request.path == "/up" || request.path == "/health" }
  # }
end
