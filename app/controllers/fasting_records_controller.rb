# app/controllers/fasting_records_controller.rb
class FastingRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_scope
  before_action :set_record, only: %i[
    show edit update destroy finish
    edit_comment update_comment
  ]

  # 記録一覧ページ（フィルタ付き）
  def index
    scope = @scope.order(Arel.sql("COALESCE(end_time, start_time) DESC"))

    case normalize_status(params[:status])
    when "achieved"
      scope = scope.respond_to?(:achieved)   ? scope.achieved   : scope.where(success: true).where.not(end_time: nil)
    when "unachieved"
      scope = scope.respond_to?(:unachieved) ? scope.unachieved : scope.where(success: false).where.not(end_time: nil)
    when "in_progress"
      scope = scope.respond_to?(:running)    ? scope.running    : scope.where(end_time: nil)
    else
      # すべて
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
      redirect_to fasting_records_path, notice: "記録を追加しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    attrs = fasting_record_params.to_h

    # 終了済みは基本ロック
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

  # 今すぐ開始（進行中があればブロック／18h+ は追加確認）
  def start
    if @scope.where(end_time: nil).exists?
      redirect_to mypage_path, alert: "進行中の記録があります" and return
    end

    hours = params[:target_hours].presence&.to_i
    if hours.nil? || hours <= 0
      redirect_to mypage_path, alert: "目標時間を選択してください" and return
    end

    # 18h 以上なら追加確認（/health-notice/long）
    if long_notice_required?(hours)
      if params[:confirmed_long_notice] != "1"
        redirect_to long_health_notice_path(hours: hours) and return
      end
      if params[:agree_long] != "1"
        redirect_to long_health_notice_path(hours: hours), alert: "同意が必要です。" and return
      end
    end

    record = @scope.new(start_time: Time.current, target_hours: hours, success: nil)

    if record.save
      redirect_to mypage_path, notice: "開始しました"
    else
      redirect_to mypage_path, alert: record.errors.full_messages.to_sentence
    end
  end

  # 今すぐ終了（終了時に自動で success を判定）
  def finish
    if @record.end_time.present?
      redirect_to mypage_path, alert: "この記録は終了済みです。" and return
    end

    @record.end_time = Time.current
    @record.success  = @record.auto_success?
    @record.save!

    redirect_to edit_fasting_record_path(@record),
                notice: "終了しました。コメントをどうぞ"
  end

  # -----------------------------
  # コメント専用: 編集 / 更新
  # -----------------------------
  def edit_comment
    # 表示のみ（フォームは comment フィールドだけ）
  end

  def update_comment
    if @record.update(comment_params)
      redirect_to @record, notice: "コメントを保存しました"
    else
      flash.now[:alert] = "コメントを保存できませんでした"
      render :edit_comment, status: :unprocessable_entity
    end
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

  # コメント専用 Strong Params（user_id 等は触らない）
  def comment_params
    params.require(:fasting_record).permit(:comment)
  end

  # 旧→新フィルタキー正規化
  def normalize_status(s)
    case s
    when "success"   then "achieved"
    when "failure"   then "unachieved"
    when "achieved", "unachieved", "in_progress" then s
    else
      nil
    end
  end

  # 18h 以上で注意画面
  def long_notice_required?(hours)
    hours.to_i >= 18
  end

  # 結果に応じてポジティブな文言
  def flash_message_for(record)
    return "保存しました。" unless record.end_time.present?

    case record.success
    when true  then "保存しました。達成おめでとう！ "
    when false then "保存しました。次は達成できますように！"
    else            "保存しました。"
    end
  end
end
