class AddHealthNoticeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :accepted_health_notice_at, :datetime
    add_column :users, :health_notice_version, :string
  end
end
