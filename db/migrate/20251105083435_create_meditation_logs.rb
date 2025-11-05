# db/migrate/xxxxxxxxxxxx_create_meditation_logs.rb
class CreateMeditationLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :meditation_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer    :duration_sec, null: false, default: 0
      t.datetime   :started_at   # あれば使う

      t.timestamps
    end

    add_index :meditation_logs, [:user_id, :started_at]
    add_index :meditation_logs, [:user_id, :created_at]
  end
end
