class AddIndexUsersOnProviderUidUnique < ActiveRecord::Migration[8.0]
  def up
    return if index_exists?(:users, %i[provider uid], unique: true)
    remove_index :users, column: %i[provider uid] if index_exists?(:users, %i[provider uid], unique: false)
    add_index :users, %i[provider uid], unique: true
  end

  def down
    remove_index :users, column: %i[provider uid] if index_exists?(:users, %i[provider uid], unique: true)
  end
end
