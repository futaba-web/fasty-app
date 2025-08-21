# db/migrate/xxxxxx_rename_username_to_name_in_users.rb
class RenameUsernameToNameInUsers < ActiveRecord::Migration[7.2]
  def up
    # 既存の一意インデックスを安全に張り替え
    if index_exists?(:users, :username, unique: true)
      remove_index :users, :username
    elsif index_name_exists?(:users, :index_users_on_username)
      remove_index :users, name: :index_users_on_username
    end

    rename_column :users, :username, :name if column_exists?(:users, :username)

    add_index :users, :name, unique: true unless index_exists?(:users, :name, unique: true)
  end

  def down
    remove_index :users, :name if index_exists?(:users, :name, unique: true)
    rename_column :users, :name, :username if column_exists?(:users, :name)
    add_index :users, :username, unique: true unless index_exists?(:users, :username, unique: true)
  end
end
