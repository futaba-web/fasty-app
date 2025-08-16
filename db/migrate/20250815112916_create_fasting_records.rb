class CreateFastingRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :fasting_records do |t|
      t.bigint :user_id
      t.datetime :start_time, null: false
      t.datetime :end_time
      t.integer :target_hours
      t.text :comment
      t.boolean :success

      t.timestamps
    end
    add_index :fasting_records, [:user_id, :start_time]
    add_index :fasting_records, [:user_id, :end_time]
  end
end
