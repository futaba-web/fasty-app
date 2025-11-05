# app/controllers/meditations_controller.rb
class MeditationsController < ApplicationController
  before_action :authenticate_user!  # ログイン後に見る想定

  def index
    # === 1) 今週の瞑想ステータス（バナー用） =========================
    # 週の基準は「月曜はじまり」。必要なら :sunday に変更可。
    week_start = Time.zone.now.beginning_of_week(:monday).beginning_of_day
    week_end   = week_start.end_of_week(:monday).end_of_day

    # NOTE:
    # - ログの基準カラムが :started_at なら created_at を置き換えてください。
    # - duration_sec（秒）の合計を分に変換して丸めています。
    logs_in_week = current_user.meditation_logs.where(created_at: week_start..week_end)

    @weekly_count   = logs_in_week.count
    @weekly_minutes = (logs_in_week.sum(:duration_sec) / 60.0).round

    @banner_message =
      if @weekly_count.zero?
        "まずは5分から始めてみましょう🌱"
      else
        "今週の瞑想は#{@weekly_count}回／合計#{@weekly_minutes}分です"
      end

    # === 2) 瞑想メニュー（既存のYAML読み込み） ========================
    path = Rails.root.join("config/meditations.yml")
    raw  = YAML.safe_load_file(path, aliases: false) rescue []

    @meditations = Array(raw).map { |m|
      {
        title:        m["title"].to_s,
        url:          m["url"].to_s,
        duration_min: m["duration_min"].to_i,
        tags:         Array(m["tags"]).map(&:to_s)
      }
    }.sort_by { |m| m[:duration_min] }
  end
end
