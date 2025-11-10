# db/migrate/XXXXXXXXXXXXXX_add_uid_to_fasting_records.rb
class AddUidToFastingRecords < ActiveRecord::Migration[7.2]
  def up
    # 一旦NULL許可で追加 → バックフィル → NOT NULL化
    add_column :fasting_records, :uid, :binary, limit: 16, null: true, comment: "Public UUID (binary16)"
    add_index  :fasting_records, :uid, unique: true

    # 既存データ全件にUUID(16バイト)を付与
    # MySQL: UUID() を 32hex に → REPLACEで'-'除去 → UNHEXで16バイトへ
    execute <<~SQL.squish
      UPDATE fasting_records
         SET uid = UNHEX(REPLACE(UUID(),'-',''))
       WHERE uid IS NULL;
    SQL

    change_column_null :fasting_records, :uid, false
  end

  def down
    remove_index  :fasting_records, :uid
    remove_column :fasting_records, :uid
  end
end
