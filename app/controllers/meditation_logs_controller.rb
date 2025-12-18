# frozen_string_literal: true

class MeditationLogsController < ApplicationController
  before_action :authenticate_user!, only: :create

  def create
    # ここに来る時点で必ずログイン済み
    log = current_user.meditation_logs.build(meditation_log_params)

    if log.save
      redirect_to meditation_summary_path, notice: "瞑想を記録しました"
    else
      redirect_to meditation_summary_path,
                  alert: log.errors.full_messages.to_sentence
    end
  end

  private

  def meditation_log_params
    # ★ Rails 8対策：キーが無ければ空Hashを返す
    params.fetch(:meditation_log, {}).permit(:duration_sec, :started_at)
  end
end
