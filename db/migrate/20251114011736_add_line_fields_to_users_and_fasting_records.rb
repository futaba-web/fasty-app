# db/migrate/XXXXXXXXXXXX_add_line_fields_to_users_and_fasting_records.rb
class AddLineFieldsToUsersAndFastingRecords < ActiveRecord::Migration[8.0]
  def change
    # === users ===
    add_column :users, :line_user_id, :string
    add_column :users, :line_notify_enabled, :boolean, null: false, default: false

    add_index :users, :line_user_id, unique: true, where: "line_user_id IS NOT NULL"

    # === fasting_records ===
    add_column :fasting_records, :line_notified_at, :datetime
    # ここでは「終了予定時刻」は既存の planned_end_at カラムを想定しています
    # 名前が違う場合は、後でスコープ実装のときに読み替えればOKです
  end
end
