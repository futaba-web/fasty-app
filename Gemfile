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
gem "sprockets-rails"           # 必要なら使用
gem "tailwindcss-rails"         # Node不要
# gem "dartsass-rails"          # SCSSを使わないなら不要
gem "sassc-rails", "~> 2.1"     # SprocketsでSCSS使うなら

# --- App libs ---
gem "kaminari"
gem "devise", "~> 4.9"
gem "bcrypt", "~> 3.1"          # Deviseのデフォルト暗号化（必須）
# gem "rails-i18n"              # I18nの各国語（必要なら）

# --- OmniAuth / Google Login ---
# まずは保守的に固定→動作確認後に緩める運用に
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "omniauth-oauth2", "~> 1.8"
gem "omniauth-google-oauth2", "~> 1.2"
gem "oauth2", "~> 2.0.12"

# Windows/JRuby向けタイムゾーンデータ
gem "tzinfo-data", platforms: %i[windows jruby]

# --- Production（Render/本番）---
group :production do
  gem "pg", "~> 1.5"            # 本番はPostgreSQL
end

# --- Development / Test ---
group :development, :test do
  gem "mysql2", "~> 0.5"        # ローカル/CIはMySQL

  # dotenv: .env.* を読み込み（開発/テストのみ）
  gem "dotenv-rails"

  # テスト
  gem "rspec-rails", "~> 6.1"   # 使っていなければ削除OK

  # デバッグ & セキュリティ & Lint
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "letter_opener_web"       # /letter_opener で開発メール確認
end
