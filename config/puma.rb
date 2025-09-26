# config/puma.rb

# スレッド数（最小/最大）
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count).to_i
threads min_threads_count, max_threads_count

# ポート・環境
port        ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "development")

# PIDファイル（Herokuでは未使用だが他環境向けに用意）
pidfile     ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Herokuの並列ワーカー数（環境変数がある場合のみ設定）
# 例: heroku config:set WEB_CONCURRENCY=2
if ENV["WEB_CONCURRENCY"]
  workers Integer(ENV.fetch("WEB_CONCURRENCY"))
  preload_app!
end

# bin/rails restart で再起動できるように
plugin :tmp_restart
