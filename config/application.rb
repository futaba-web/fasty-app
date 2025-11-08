# config/application.rb
require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

require "uri"

module FastyApp
  class Application < Rails::Application
    config.load_defaults 7.2

    # app/lib のうち .rb 以外をautoload対象から外す
    config.autoload_lib(ignore: %w[assets tasks])

    # 自作ミドルウェアのディレクトリを読み込む（補助）
    middleware_path = Rails.root.join("app/middleware")
    config.autoload_paths   << middleware_path
    config.eager_load_paths << middleware_path

    # === Canonical Host（本番のみ / PRIMARY_HOST があるときだけ） ===
    if Rails.env.production? && ENV["PRIMARY_HOST"].present?
      # ← ここで明示的にロード（重要）
      require Rails.root.join("app/middleware/canonical_host")

      # Rack::Runtime より前に差し込み、早期 301
      config.middleware.insert_before Rack::Runtime, CanonicalHost
    end

    config.generators.system_tests = nil
    config.time_zone = "Tokyo"
    config.i18n.default_locale = :ja
  end
end
