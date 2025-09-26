# Gemfile
source "https://rubygems.org"
ruby "3.2.2"

# --- Core ---
gem "rails", "~> 8.0.2"
gem "puma", ">= 5.0"
gem "bootsnap", require: false

# --- Frontend / Assets ---
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "sprockets-rails"      # 必要なら残す（Rails 8 でも使用可）
gem "tailwindcss-rails"    # Node不要
gem "dartsass-rails"       # Node不要（Sassビルド）

# --- App libs ---
gem "kaminari"
gem "devise", "~> 4.9"

# Windows/JRuby向けタイムゾーンデータ
gem "tzinfo-data", platforms: %i[windows jruby]

# --- Production（Heroku）---
# HerokuではPostgresを使う
group :production do
  gem "pg", "~> 1.5"
end

# --- Development / Test ---
group :development, :test do
  # ローカル/テストはMySQLを利用（Herokuでは使わない）
  gem "mysql2", "~> 0.5"

  # デバッグ & 静的解析
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

# ActiveStorage の画像変換を使う場合は有効化
# gem "image_processing", "~> 1.2"
