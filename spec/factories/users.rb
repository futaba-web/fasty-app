# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:name)  { |n| "テストユーザー#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }

    # ▼ LINE 通知まわり（今回追加）
    line_notify_enabled { false }  # デフォルトは OFF
    line_user_id        { nil }    # OFF のときは nil でOK

    trait :line_notify_on do
      line_notify_enabled { true }
      line_user_id        { "U_dummy_line_user_id" }
    end
  end
end
