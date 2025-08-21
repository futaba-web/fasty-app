# db/migrate/xxxxxx_add_active_user_guard_to_fasting_records.rb
class AddActiveUserGuardToFastingRecords < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      ALTER TABLE fasting_records
      ADD COLUMN active_user_id BIGINT
        GENERATED ALWAYS AS (IF(end_time IS NULL, user_id, NULL)) STORED;
    SQL
    add_index :fasting_records, :active_user_id, unique: true
  end

  def down
    remove_index :fasting_records, :active_user_id
    remove_column :fasting_records, :active_user_id
  end
end
