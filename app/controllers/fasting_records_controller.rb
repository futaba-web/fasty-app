class FastingRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_scope
  before_action :set_record, only: %i[show edit update destroy finish]

  # 記録一覧ページ（フィルタ付き）
  def index
    scope = @scope.order(start_time: :desc)

    case params[:status]
    when "success"
      scope = scope.where(success: true)
    when "failure"
      scope = scope.where(success: false)
    end

    @records = if defined?(Kaminari)
                  scope.page(params[:page]).per(20)
    else
                scope.limit(20)
    end
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

  # 今すぐ開始（進行中があればブロック）
  def start
    if @scope.running.exists?
      redirect_to mypage_path, alert: "進行中の記録があります" and return
    end

    hours  = params[:target_hours].presence&.to_i
    record = @scope.new(start_time: Time.current, target_hours: hours, success: nil)

    if record.save
      redirect_to mypage_path, notice: "ファスティングを開始しました"
    else
      redirect_to mypage_path, alert: record.errors.full_messages.to_sentence
    end
  end

  # 今すぐ終了（params[:success] を true/false で受ける／未指定なら nil）
  def finish
    if @record.end_time.present?
      redirect_to mypage_path, alert: "この記録はすでに終了しています。" and return
    end

    @record.update!(end_time: Time.current, success: nil) # 成否は未確定のまま
    redirect_to edit_fasting_record_path(@record),
                notice: "ファスティングを終了しました。結果（達成/失敗）を選択して保存してください。"
  end


  def destroy
    @record.destroy!
    redirect_to fasting_records_path, notice: "記録を削除しました"
  end

  private

  def set_scope
    # 自分の記録だけを対象にする
    @scope = current_user.fasting_records
  end

  def set_record
    # ID直叩きでも他人のは取れない
    @record = @scope.find(params[:id])
  end

  # create/update 共通 Strong Params
  def fasting_record_params
    params.require(:fasting_record).permit(:start_time, :end_time, :target_hours, :comment, :success)
  end
end
