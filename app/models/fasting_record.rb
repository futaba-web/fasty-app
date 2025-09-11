class FastingRecord < ApplicationRecord
  belongs_to :user, optional: true

  TARGET_HOURS_CHOICES = [ 12, 14, 16, 18, 20, 22, 24 ].freeze
  GRACE_SECONDS = 30 # 判定の猶予（必要に応じて 0〜60 で調整）

  scope :running, -> { where(end_time: nil) }

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

  def running?
    end_time.nil?
  end

  # 開始〜終了の秒数（両方あるときのみ）
  def duration_seconds
    return nil unless start_time && end_time
    (end_time - start_time).to_i
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
