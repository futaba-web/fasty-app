# app/controllers/fasting_records_controller.rb
class FastingRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_scope
  before_action :set_record, only: %i[show edit update destroy finish]

  def index
    @today   = Time.zone.today
    @running = @scope.running.order(start_time: :desc).first
    @records = @scope.order(start_time: :desc).limit(30)
  end

  def show; end

  def new
    @record = @scope.new(start_time: Time.current, end_time: Time.current)
  end

  def create
    @record = @scope.new(fasting_record_params)
    if @record.save
      redirect_to fasting_records_path, notice: "新しい記録を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @record.update(fasting_record_params)
      redirect_to @record, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 開始（進行中があればブロック）
  def start
    if @scope.running.exists?
      redirect_to fasting_records_path, alert: "進行中の記録があります" and return
    end

    hours  = params[:target_hours].presence&.to_i
    record = @scope.new(start_time: Time.current, target_hours: hours)

    if record.save
      redirect_to fasting_records_path, notice: "ファスティングを開始しました"
    else
      redirect_to fasting_records_path, alert: record.errors.full_messages.to_sentence
    end
  end

  # 終了
  def finish
    result = params.key?(:success) ? ActiveModel::Type::Boolean.new.cast(params[:success]) : nil
    if @record.update(end_time: Time.current, success: result)
      redirect_to fasting_records_path, notice: "ファスティングを終了しました"
    else
      redirect_back fallback_location: fasting_records_path, alert: @record.errors.full_messages.to_sentence
    end
  end

  def destroy
    @record.destroy!
    redirect_to fasting_records_path, notice: "記録を削除しました"
  end

  private

  def set_scope
    # ★ ここが重要: 自分の記録だけを対象にする
    @scope = current_user.fasting_records
  end

  def set_record
    # ★ ID直叩きでも他人のは取れない
    @record = @scope.find(params[:id])
  end

  # ★ create/update 両方で同じStrong Params名を使う
  def fasting_record_params
    params.require(:fasting_record).permit(:start_time, :end_time, :target_hours, :comment, :success)
  end
end
