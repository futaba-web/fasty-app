# lib/tasks/line.rake
namespace :line do
  desc "ファスティング終了予定のLINE通知を送信する"
  task send_fasting_finish_notifications: :environment do
    Line::FastingFinishNotifier.run!
  end
end
