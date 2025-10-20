# config/environments/development.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # コードのホットリロード
  config.enable_reloading = true
  config.eager_load = false

  # エラー詳細表示
  config.consider_all_requests_local = true

  # Server-Timing
  config.server_timing = true

  # キャッシュ切替（bin/rails dev:cache）
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.cache_store = :memory_store
    config.public_file_server.headers = { "Cache-Control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  # Active Storage はローカル
  config.active_storage.service = :local

  # ---- メール設定（開発）------------------------------------------
  # 送信エラーは気づけるように true 推奨
  config.action_mailer.raise_delivery_errors = true

  # メールテンプレはキャッシュしない
  config.action_mailer.perform_caching = false

  # URL 生成（Devise のメール内リンクで使用）
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
  config.action_mailer.asset_host = "http://localhost:3000"

  # letter_opener_web でブラウザ受信箱を使う
  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :letter_opener_web
  # ---------------------------------------------------------------

  # （※ MailHog を使う場合の例。必要になったら上をコメントアウトしてこちらを有効化）
  # config.action_mailer.perform_deliveries = true
  # config.action_mailer.delivery_method = :smtp
  # config.action_mailer.smtp_settings = { address: "mailhog", port: 1025 }

  # 非推奨警告
  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # マイグレーション未適用でエラー
  config.active_record.migration_error = :page_load

  # ログにクエリ発生箇所をハイライト
  config.active_record.verbose_query_logs = true
  config.active_job.verbose_enqueue_logs = true

  # アセットのログ静かに
  config.assets.quiet = true

  # ビューにテンプレートのファイル名を注釈
  config.action_view.annotate_rendered_view_with_filenames = true

  # before_action の only/except で存在しないアクションを指定したら例外
  config.action_controller.raise_on_missing_callback_actions = true

  # 生成コマンドで RuboCop 自動修正（必要なら）
  # config.generators.apply_rubocop_autocorrect_after_generate!
end
