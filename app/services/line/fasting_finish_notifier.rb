# app/services/line/fasting_finish_notifier.rb
# frozen_string_literal: true

module Line
  class FastingFinishNotifier
    # 手動実行用: Line::FastingFinishNotifier.run!
    def self.run!(now = Time.current)
      FastingRecord
        .joins(:user)
        .where.not(end_time: nil)                      # end_time が入っている
        .where(line_notified_at: nil)                  # まだ通知してない
        .where("fasting_records.end_time <= ?", now)   # 終了時刻を過ぎている
        .where(users: { line_notify_enabled: true })   # 通知 ON ユーザー
        .where.not(users: { line_user_id: nil })       # line_user_id を持っている
        .find_each do |record|
          new(record).notify!
        end
      nil
    end

    def initialize(record)
      @record = record
    end

    def notify!
      user = @record.user
      return unless user&.line_notify_enabled? && user.line_user_id.present?

      LineMessaging.push_text(user, message_text)

      @record.update!(line_notified_at: Time.current)
    rescue StandardError => e
      Rails.logger.error(
        "[Line::FastingFinishNotifier] failed for fasting_record_id=#{@record.id}: #{e.class} #{e.message}"
      )
    end

    private

    def message_text
      "ファスティングお疲れさまです！そろそろ終了予定の時間です。"
    end
  end
end
