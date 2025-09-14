class FastingRecord < ApplicationRecord
  belongs_to :user, optional: true

  TARGET_HOURS_CHOICES = [12, 14, 16, 18, 20, 22, 24].freeze
  GRACE_SECONDS = 30 # 判定の猶予（必要に応じて 0〜60 で調整）

  scope :running,  -> { where(end_time: nil) }
  scope :finished, -> { where.not(end_time: nil) }
  scope :achieved, -> { finished.where(success: true) }
  scope :unachieved, -> { finished.where(success: [false, nil]) }

  # 同一ユーザーで「進行中（end_time: nil）」が複数できないように
  validates :user_id, uniqueness: { conditions: -> { where(end_time: nil) } }

  validates :start_time, presence: true
  validates :target_hours, presence: true, inclusion: { in: TARGET_HOURS_CHOICES }
  validate  :end_after_start
  # end_time の必須化は「手動更新時」に限定（自動終了フローでは未入力保存も許すため）
  validates :end_time, presence: true, on: :manual

  # 終了時間が入ったら自動判定で success を埋める
  before_validation :auto_set_success,
                    if: -> { start_time.present? && end_time.present? && target_hours.present? }

  # ====== 一覧/表示用ユーティリティ ======

  # 進行中か？
  def running?
    end_time.nil?
  end

  # 成功・未達成・進行中のキー（ビューのバッジ分岐用）
  # :achieved / :unachieved / :in_progress
  def status_key
    return :in_progress if running?
    success? ? :achieved : :unachieved
  end

  # 一覧に出す日付（終了があれば終了日、なければ開始日）
  def date_for_list
    (end_time || start_time)&.in_time_zone&.to_date
  end

  # 一覧の「ファスティング⌛️xx時間yy分」に使う表示用の経過時間
  # 進行中は現在時刻までで算出、終了済みは start..end
  def duration_text
    h, m = elapsed_hm
    format("%d時間%02d分", h, m)
  end

  # 目標表示用 "xxh"
  def target_hours_label
    "#{target_hours}h"
  end

  # コメント（comment / note / memo のどれかを採用）
  def comment_text
    self[:comment].presence || self[:note].presence || self[:memo].presence
  end

  # ====== 判定/内部計算 ======

  # 成否判定に使う「確定の秒数」（終了しているときのみ）
  def duration_seconds
    return nil unless start_time && end_time
    (end_time - start_time).to_i
  end

  # 表示用の経過秒（終了済みなら確定、進行中なら現在時刻まで）
  def elapsed_seconds
    return nil unless start_time
    ((end_time || Time.current) - start_time).to_i
  end

  def elapsed_hm
    s = elapsed_seconds
    return [0, 0] unless s
    mins = s / 60
    [mins / 60, mins % 60]
  end

  # 自動判定（猶予付き）
  def auto_success?
    return nil unless target_hours && duration_seconds
    duration_seconds >= (target_hours.hours - GRACE_SECONDS)
  end

  # アプリ側からの「終了」操作用ヘルパ
  def finish!(at: Time.current)
    self.end_time = at
    self.success  = auto_success?
    save!
  end

  private

  def auto_set_success
    self.success = auto_success?
  end

  def end_after_start
    return if end_time.blank? || start_time.blank?
    errors.add(:end_time, "は開始より後にしてください") if end_time < start_time
  end
end
