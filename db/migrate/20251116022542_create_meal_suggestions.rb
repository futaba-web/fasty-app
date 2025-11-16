class CreateMealSuggestions < ActiveRecord::Migration[7.1] # バージョンはプロジェクトに合わせて
  def change
    create_table :meal_suggestions do |t|
      t.references :user, null: false, foreign_key: true
      t.date   :target_date, null: false
      t.string :phase,       null: false, default: "insight_based"
      t.json  :content,      null: false  # JSONB ではなく JSON

      t.timestamps
    end

    add_index :meal_suggestions, [:user_id, :target_date], unique: true
  end
end
