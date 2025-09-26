# db/migrate/XXXXXXXXXXXXXX_ensure_open_record_uniqueness.rb
class EnsureOpenRecordUniqueness < ActiveRecord::Migration[7.2]
  # PG の部分ユニーク INDEX を使うときはトランザクション外で実行
  disable_ddl_transaction!

  def up
    case ActiveRecord::Base.connection.adapter_name
    when /PostgreSQL/i
      # end_time が NULL の行だけに一意制約（= 未終了はユーザーごとに1件）
      execute <<~SQL
        CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS idx_fasting_open_unique
        ON fasting_records (user_id)
        WHERE end_time IS NULL;
      SQL
    when /Mysql/i
      # MySQL は部分 INDEX がないので、生成列 + 複合ユニーク INDEX
      execute <<~SQL
        ALTER TABLE fasting_records
        ADD COLUMN IF NOT EXISTS open_guard BOOLEAN
        GENERATED ALWAYS AS (end_time IS NULL) STORED;
      SQL
      execute <<~SQL
        CREATE UNIQUE INDEX idx_fasting_open_unique
        ON fasting_records (user_id, open_guard);
      SQL
    end
  end

  def down
    if ActiveRecord::Base.connection.adapter_name =~ /PostgreSQL/i
      execute "DROP INDEX IF EXISTS idx_fasting_open_unique;"
    else
      execute "DROP INDEX IF EXISTS idx_fasting_open_unique ON fasting_records;"
      execute "ALTER TABLE fasting_records DROP COLUMN IF EXISTS open_guard;"
    end
  end
end
