class MealSuggestion < ApplicationRecord
  belongs_to :user

  validates :target_date, presence: true
  validates :phase,       presence: true
  validates :content,     presence: true
end
