# spec/factories/users.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    # Devise の user で最低限必要そうな属性だけにしておく
  end
end
