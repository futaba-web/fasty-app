# db/migrate/20250819104420_add_user_to_fasting_records.rb
class AddUserToFastingRecords < ActiveRecord::Migration[7.2]
  def change
    # user_id が無い場合のみ追加（NULL許可にしておく）
    unless column_exists?(:fasting_records, :user_id)
      add_reference :fasting_records, :user, null: true, foreign_key: true
    end

    # インデックスなければ追加
    unless index_exists?(:fasting_records, :user_id)
      add_index :fasting_records, :user_id
    end

    # 外部キーなければ追加
    unless foreign_key_exists?(:fasting_records, :users)
      add_foreign_key :fasting_records, :users
    end
  end
end
