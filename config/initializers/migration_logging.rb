# 本番起動時に一度だけマイグレーション状態をログ出力
Rails.application.config.after_initialize do
  begin
    ctx = ActiveRecord::Base.connection.migration_context
    current = ctx.current_version
    pending = false
    begin
      ActiveRecord::Migration.check_pending!
    rescue ActiveRecord::PendingMigrationError
      pending = true
    end
    Rails.logger.info("[MIGRATION] current_version=#{current} pending=#{pending}")
  rescue => e
    Rails.logger.error("[MIGRATION] check_failed=#{e.class}: #{e.message}")
  end
end
