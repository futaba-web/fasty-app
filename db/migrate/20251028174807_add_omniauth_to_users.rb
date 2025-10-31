# db/migrate/20251028174807_add_omniauth_to_users.rb
class AddOmniauthToUsers < ActiveRecord::Migration[8.0]
  def change
    # 既に存在する環境でも落ちないように存在チェック付きで追加
    add_column :users, :provider, :string unless column_exists?(:users, :provider)
    add_column :users, :uid,      :string unless column_exists?(:users, :uid)

    # provider+uid の複合ユニークインデックス（連携の一意性を担保）
    unless index_exists?(:users, %i[provider uid], unique: true)
      add_index :users, %i[provider uid], unique: true
    end

    # 念のため email のユニークインデックスも保証
    add_index :users, :email, unique: true unless index_exists?(:users, :email, unique: true)
  end
end
