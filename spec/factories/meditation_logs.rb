FactoryBot.define do
  factory :meditation_log do
    association :user
    duration_sec { 300 }
    started_at { Time.zone.now }
  end
end
