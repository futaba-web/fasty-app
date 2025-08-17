class FastingRecord < ApplicationRecord
    TARGET_HOURS_CHOICES = [ 12, 14, 16, 18, 20, 22, 24 ].freeze
    # belongs_to :user, optional: true #Users導入後に外してOK

    validates :start_time, presence: true
    validates :target_hours, presence: true, inclusion: { in: TARGET_HOURS_CHOICES }
    validate :end_after_start
    validates :end_time, presence: true, on: :manual

    scope :running, -> { where(end_time: nil) }

    def running? = end_time.nil?

    def duration_seconds
        ((end_time || Time.current) - start_time).to_i
    end

    def finish!(result: nil)
        update!(end_time: Time.current, success: result)
    end

    private

    def end_after_start
        return if end_time.blank? || start_time.blank?
        errors.add(:end_time, "は開始より後にしてください") if end_time < start_time
    end
end
