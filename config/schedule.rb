# config/schedule.rb

# Whenever の基本設定
set :environment, ENV.fetch("RAILS_ENV", "development")
set :output, "log/cron.log"

# タイムゾーン（日本時間）
env :TZ, "Asia/Tokyo"

# =========================
# ここに既存のジョブがあれば並べて書く
# 例:
# every 1.hour do
#   rake "articles:publish_wait"
# end
# =========================

# ファスティング終了予定時刻の LINE 通知
# - 5分おきに「終了予定時刻を過ぎた & まだ通知していない記録」に対して
#   Rakeタスク経由で push 通知を送る
every 5.minutes do
  rake "line:send_fasting_finish_notifications"
end
