# app/controllers/health_notice_controller.rb
class HealthNoticeController < ApplicationController
  # HealthNotice 配下は同意チェックによるリダイレクト対象外（明示）
  skip_before_action :require_health_notice!, only: %i[show create long], raise: false
  before_action :authenticate_user!

  def show
    # すでに同意済みなら元のページ（またはマイページ）へ
    if current_user.health_notice_version == notice_version
      redirect_back_or_to_after_consent and return
    end
    # 画面はそのまま表示
  end

  # 18h 以上の開始時の追加確認（24h 以上なら強調）
  def long
    @hours = params[:hours].to_i
    @very_long = @hours >= 24

    if @hours <= 0
      redirect_to mypage_path, alert: "目標時間が不明です。" and return
    end
    # 画面はそのまま表示（views/health_notice/long.html.erb を用意）
  end

  def create
    unless params[:agree] == "1"
      redirect_to health_notice_path, alert: "同意チェックが必要です。"
      return
    end

    ok = current_user.update(
      accepted_health_notice_at: Time.current,
      health_notice_version: notice_version
    )

    if ok
      redirect_back_or_to_after_consent notice: "同意を保存しました。"
    else
      redirect_to health_notice_path, alert: "保存に失敗しました。もう一度お試しください。"
    end
  end

  private

  def notice_version
    Rails.configuration.x.health_notice.version
  end

  def redirect_back_or_to_after_consent(**flash)
    # Devise の保存済み戻り先 or マイページへ
    redirect_to(stored_location_for(:user).presence || mypage_path, **flash)
  end
end
