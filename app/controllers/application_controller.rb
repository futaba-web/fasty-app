# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :require_health_notice!
  before_action :configure_permitted_parameters, if: :devise_controller?
  layout :layout_by_resource

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,        keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  # ログイン後の遷移先（必ずマイページへ）
  def after_sign_in_path_for(resource_or_scope)
    mypage_path
  end

  # サインアップ後もマイページへ（任意だが合わせておくと自然）
  def after_sign_up_path_for(resource)
    mypage_path
  end

  # ログアウト後の遷移先
  def after_sign_out_path_for(resource_or_scope)
    if respond_to?(:unauthenticated_root_path)
      unauthenticated_root_path
    else
      root_path
    end
  end

  private

  def layout_by_resource
    devise_controller? ? "devise" : "application"
  end

  def require_health_notice!
    return unless user_signed_in?

    required_version = Rails.application.config.x.health_notice.version

    # 同意画面自体では発火させない（将来の名前空間にも耐性）
    return if controller_path.start_with?("health_notice")

    # すでに同意済みならそのまま
    return if current_user.health_notice_version == required_version

    # 戻り先を保存して同意画面へ
    store_location_for(:user, request.fullpath) if request.get?
    redirect_to health_notice_path
  end
end
