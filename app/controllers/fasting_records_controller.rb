class FastingRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_scope
  before_action :set_record, only: %i[show edit update destroy finish]

  # 記録一覧ページ（フィルタ付き）
  def index
    # 終了があれば終了日時、なければ開始日時で新しい順
    scope = @scope.order(Arel.sql("COALESCE(end_time, start_time) DESC"))

    case normalize_status(params[:status])
    when "achieved"
      scope = scope.respond_to?(:achieved) ? scope.achieved : scope.where(success: true).where.not(end_time: nil)
    when "unachieved"
      scope = scope.respond_to?(:unachieved) ? scope.unachieved : scope.where(success: false).where.not(end_time: nil)
    when "in_progress"
      scope = scope.respond_to?(:running) ? scope.running : scope.where(end_time: nil)
    else
      # すべて表示
    end

    @records =
      if defined?(Kaminari)
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
    attrs = fasting_record_params.to_h

    # 終了済みは基本ロック：明示フラグがない限り start_time / end_time / target_hours は上書きしない
    if @record.end_time.present?
      attrs.delete("start_time")   if params[:allow_change_start_time].blank?
      attrs.delete("end_time")     if params[:allow_change_end_time].blank?
      attrs.delete("target_hours") if params[:allow_change_target_hours].blank?
    end

    if @record.update(attrs)
      redirect_to @record, notice: flash_message_for(@record)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 今すぐ開始（進行中があればブロック）
  def start
    if @scope.where(end_time: nil).exists?
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

  # 今すぐ終了（終了時に自動で success を判定）
  def finish
    if @record.end_time.present?
      redirect_to mypage_path, alert: "この記録はすでに終了しています。" and return
    end

    @record.end_time = Time.current
    @record.success  = @record.auto_success? # 念のため明示再計算
    @record.save!

    redirect_to edit_fasting_record_path(@record),
                notice: "ファスティングを終了しました。今の気持ちをコメントしましょう"
  end

  def destroy
    @record.destroy!
    redirect_to fasting_records_path, notice: "記録を削除しました"
  end

  private

  def set_scope
    @scope = current_user.fasting_records
  end

  def set_record
    @record = @scope.find(params[:id])
  end

  # create/update 共通 Strong Params
  def fasting_record_params
    params.require(:fasting_record).permit(:start_time, :end_time, :target_hours, :comment)
  end

  # "success"/"failure"（旧）→ "achieved"/"unachieved"（新）へ正規化
  def normalize_status(s)
    case s
    when "success"   then "achieved"
    when "failure"   then "unachieved"
    when "achieved", "unachieved", "in_progress" then s
    else nil
    end
  end

  # 結果に応じてポジティブな文言を返す
  def flash_message_for(record)
    return "保存しました。" unless record.end_time.present?

    case record.success
    when true  then "保存しました。達成おめでとう！🎉 いい流れ、今日は自分を褒めよう。"
    when false then "保存しました。おつかれさま！今回は休息デー。明日に向けてリスタート！"
    else            "保存しました。"
    end
  end
end
