FactoryBot.define do
  factory :meal_suggestion do
    user { nil }
    target_date { "2025-11-16" }
    phase { "MyString" }
    content { "" }
  end
end
