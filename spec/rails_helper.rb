# spec/rails_helper.rb
# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"

# spec/support 配下のヘルパーを読み込み
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  # Rails 7.1 以降推奨の書き方（配列）
  config.fixture_paths = [Rails.root.join("spec/fixtures")]

  # トランザクションフィクスチャ
  config.use_transactional_fixtures = true

  # spec ファイルのパスから type を推論（model / request など）
  config.infer_spec_type_from_file_location!

  # Rails 由来のバックトレースを省略
  config.filter_rails_from_backtrace!

  # ==== Devise 用ヘルパー ====
  # Request spec で sign_in / sign_out を使えるようにする
  config.include Devise::Test::IntegrationHelpers, type: :request

  # ==== FactoryBot のショートカット ====
  # create / build などをそのまま使えるようにする
  config.include FactoryBot::Syntax::Methods
end
