# app/controllers/health_notice_controller.rb
class HealthNoticeController < ApplicationController
  # 無限リダイレクト防止
  skip_before_action :require_health_notice!, only: %i[show create], raise: false

  before_action :authenticate_user!

  def show
    # すでに同意済みなら元のページ（またはマイページ）へ
    if current_user.health_notice_version == notice_version
      redirect_back_or_to_after_consent and return
    end
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
    # Devise の戻り先 or マイページへ
    redirect_to(stored_location_for(:user).presence || mypage_path, **flash)
  end
end
