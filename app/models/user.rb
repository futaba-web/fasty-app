class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true, uniqueness: true, length: { maximum: 30 }
  has_many :fasting_records, dependent: :destroy

  def accepted_health_notice?
    accepted_health_notice_at.present? &&
      health_notice_version == HEALTH_NOTICE_VERSION
  end

  def needs_health_notice_consent?
    !accepted_health_notice?
  end

  def accept_health_notice!(version: HEALTH_NOTICE_VERSION)
    update!(accepted_health_notice_at: Time.current,
            health_notice_version:    version)
  end
end
