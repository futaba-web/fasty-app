class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  layout :layout_by_resource

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,        keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  # ログイン後の遷移先
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || fasting_records_path
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
end
