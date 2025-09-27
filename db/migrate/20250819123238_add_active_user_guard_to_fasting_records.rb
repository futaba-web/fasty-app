# frozen_string_literal: true

class AddActiveUserGuardToFastingRecords < ActiveRecord::Migration[8.0]
  def up
    if postgres?
      # PostgreSQL: end_time が NULL の行にだけ効くユニーク制約（＝アクティブは1件）
      add_index :fasting_records, :user_id,
                unique: true,
                where: "end_time IS NULL",
                name: "index_fasting_records_one_active_per_user"
    else
      # MySQL: 生成列 + ユニークインデックスで同等の制約を再現
      execute <<~SQL
        ALTER TABLE fasting_records
        ADD COLUMN active_user_guard BIGINT
        GENERATED ALWAYS AS (IF(end_time IS NULL, user_id, NULL)) STORED;
      SQL
      add_index :fasting_records, :active_user_guard, unique: true
    end
  end

  def down
    if postgres?
      remove_index :fasting_records, name: "index_fasting_records_one_active_per_user"
    else
      remove_index :fasting_records, :active_user_guard if index_exists?(:fasting_records, :active_user_guard)
      remove_column :fasting_records, :active_user_guard if column_exists?(:fasting_records, :active_user_guard)
    end
  end

  private

  def postgres?
    ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")
  end
end
