# app/controllers/meditation_logs_controller.rb
class MeditationLogsController < ApplicationController
  before_action :authenticate_user!

  def create
    log = current_user.meditation_logs.new(meditation_log_params)

    if log.save
      render json: { id: log.id }, status: :created
    else
      render json: { errors: log.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing => e
    render json: { errors: [ e.message ] }, status: :bad_request
  end

  private

  def meditation_log_params
    params.require(:meditation_log).permit(:duration_sec, :started_at)
  end
end
