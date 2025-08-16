class FastingRecordsController < ApplicationController
  before_action :set_scope
  before_action :set_record, only: [:show, :edit, :update, :finish]

  def index
    @running = @scope.running.last
    @records = @scope.order(start_time: :desc).limit(30)
    @today   = Time.zone.today
  end

  def show; end

  def new
    @record = FastingRecord.new(start_time: Time.current)
  end

  def create
    @record = FastingRecord.new(record_params.merge(user_id: nil))
    if @record.save
      redirect_to fasting_records_path, notice: '新しい記録を登録しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @record.update(record_params)
      redirect_to @record, notice: '更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 開始（進行中があればブロック）
  def start
    if @scope.running.exists?
      redirect_to fasting_records_path, alert: '進行中の記録があります' and return
    end

    hours  = params[:target_hours].presence&.to_i
    record = FastingRecord.new(user_id: nil, start_time: Time.current, target_hours: hours)

    if record.save
      redirect_to fasting_records_path, notice: 'ファスティングを開始しました'
    else
      redirect_to fasting_records_path, alert: record.errors.full_messages.to_sentence
    end
  end

  # 終了 → new へ誘導
  def finish
    result = params.key?(:success) ? ActiveModel::Type::Boolean.new.cast(params[:success]) : nil
    if @record.update(end_time: Time.current, success: result)
      redirect_to new_fasting_record_path, notice: 'ファスティングを終了しました。新しい記録を作成できます。'
    else
      redirect_back fallback_location: fasting_records_path, alert: @record.errors.full_messages.to_sentence
    end
  end

  private

  def set_scope
    @scope = FastingRecord.where(user_id: nil) # Users導入後は current_user.id に置換
  end

  def set_record
    @record = @scope.find(params[:id])
  end

  def record_params
    params.require(:fasting_record).permit(:start_time, :end_time, :target_hours, :comment, :success)
  end
end
