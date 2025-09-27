# db/migrate/20250926112405_ensure_open_record_uniqueness.rb
class EnsureOpenRecordUniqueness < ActiveRecord::Migration[8.0]
  # PG の部分ユニークINDEX作成に合わせてトランザクション外で実行
  disable_ddl_transaction!

  def up
    if postgres?
      # PostgreSQL: end_time が NULL の行だけ一意（＝未終了はユーザーごとに1件）
      unless index_exists?(:fasting_records, :user_id, name: "index_fasting_records_one_active_per_user")
        execute <<~SQL
          CREATE UNIQUE INDEX CONCURRENTLY index_fasting_records_one_active_per_user
          ON fasting_records (user_id)
          WHERE end_time IS NULL;
        SQL
      end
    else
      # MySQL: 生成列 + ユニークINDEX（NULL は重複可なので閉じた行は制約されない）
      unless column_exists?(:fasting_records, :active_user_guard)
        execute <<~SQL
          ALTER TABLE fasting_records
          ADD COLUMN active_user_guard BIGINT
          GENERATED ALWAYS AS (IF(end_time IS NULL, user_id, NULL)) STORED;
        SQL
      end

      unless index_exists?(:fasting_records, :active_user_guard, name: "index_fasting_records_active_user_guard", unique: true)
        add_index :fasting_records, :active_user_guard,
                  unique: true,
                  name: "index_fasting_records_active_user_guard"
      end
    end
  end

  def down
    if postgres?
      execute "DROP INDEX CONCURRENTLY IF EXISTS index_fasting_records_one_active_per_user;"
    else
      remove_index :fasting_records, name: "index_fasting_records_active_user_guard" if index_exists?(:fasting_records, name: "index_fasting_records_active_user_guard")
      remove_column :fasting_records, :active_user_guard if column_exists?(:fasting_records, :active_user_guard)
    end
  end

  private

  def postgres?
    ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")
  end
end
