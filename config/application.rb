# config/application.rb
require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require "uri" # CanonicalHost 内から URI を使うため

module FastyApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # app/lib などのうち .rb 以外をautoload対象から外す
    config.autoload_lib(ignore: %w[assets tasks])

    # === Middleware autoload/eager load =====================================
    # 自作ミドルウェアのディレクトリを確実に読み込む
    middleware_path = Rails.root.join("app/middleware")
    config.autoload_paths   << middleware_path
    config.eager_load_paths << middleware_path
    # ========================================================================

    # === Canonical Host（www統一など）========================================
    # 本番のみ、PRIMARY_HOST が設定されている場合に有効化
    if Rails.env.production? && ENV["PRIMARY_HOST"].present?
      # Rack::Runtime より前に差し込み、できるだけ早く 301 を返す
      # ここは **定数** を渡すこと（文字列だと NoMethodError になります）
      config.middleware.insert_before Rack::Runtime, CanonicalHost
    end
    # ========================================================================

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
    config.time_zone = "Tokyo"
    config.i18n.default_locale = :ja
  end
end
