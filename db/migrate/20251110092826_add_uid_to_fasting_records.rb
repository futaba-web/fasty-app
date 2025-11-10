class AddUidToFastingRecords < ActiveRecord::Migration[7.2]
  def up
    # 一旦 NULL 許可 → バックフィル → NOT NULL 化
    add_column :fasting_records, :uid, :binary, limit: 16, null: true, comment: "Public UUID (binary16)"
    add_index  :fasting_records, :uid, unique: true

    case adapter
    when :mysql
      # MySQL/MariaDB
      execute <<~SQL.squish
        UPDATE fasting_records
           SET uid = UNHEX(REPLACE(UUID(),'-',''))
         WHERE uid IS NULL;
      SQL
    when :postgres
      # PostgreSQL: pgcrypto の gen_random_uuid() を使用
      enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")
      execute <<~SQL.squish
        UPDATE fasting_records
           SET uid = decode(replace(gen_random_uuid()::text, '-', ''), 'hex')
         WHERE uid IS NULL;
      SQL
    else
      raise "Unsupported adapter for UID backfill: #{ActiveRecord::Base.connection.adapter_name}"
    end

    change_column_null :fasting_records, :uid, false
  end

  def down
    remove_index  :fasting_records, :uid
    remove_column :fasting_records, :uid
  end

  private

  def adapter
    name = ActiveRecord::Base.connection.adapter_name.downcase
    return :postgres if name.include?("postgres")
    return :mysql    if name.include?("mysql")
    :unknown
  end
end
