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
gem "sprockets-rails"      # 必要なら使用
gem "tailwindcss-rails"    # Node不要
gem "dartsass-rails"       # Node不要（Sassビルド）

# --- App libs ---
gem "kaminari"
gem "devise", "~> 4.9"

# Windows/JRuby向けタイムゾーンデータ
gem "tzinfo-data", platforms: %i[windows jruby]

# --- Production（Render/本番）---
# 本番は PostgreSQL を使用
group :production do
  gem "pg", "~> 1.5"
end

# --- Development / Test ---
group :development, :test do
  # ローカル＆CIは MySQL を使用（本番ではインストールしない）
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

gem "sassc-rails", "~> 2.1"
