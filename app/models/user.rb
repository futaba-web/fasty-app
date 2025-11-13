# app/models/user.rb
class User < ApplicationRecord
  # Devise
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2 line]

  # Associations
  has_many :fasting_records, dependent: :destroy
  has_many :meditation_logs, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true, length: { maximum: 30 }

  # 正規化
  before_validation :downcase_email

  # ===== Health Notice (既存ロジック) =====
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

  # ===== OmniAuth 共通（Google / LINE 両方で使用） =====
  # 優先順位:
  # 1) provider+uid が一致
  # 2) email が一致 → 連携情報を付与
  # 3) 新規作成（name 重複はサフィックスで回避）
  #
  # NOTE:
  # - LINE Login では email が返らないケースもあるため、
  #   その場合は changeme+ランダム@example.com を採番する。
  def self.from_omniauth(auth)
    provider = auth.provider
    uid      = auth.uid
    info     = auth.info || OpenStruct.new
    email    = info.email&.downcase

    # 1) すでに連携済み
    if (user = find_by(provider:, uid:))
      return user
    end

    # 2) email が同じ既存ユーザーを連携（Google / LINE 共通）
    if email && (user = find_by(email:))
      user.update!(provider:, uid:)
      return user
    end

    # 3) 新規作成
    base_name =
      info.name.presence ||
      [ info.first_name, info.last_name ].compact.join.presence ||
      (email ? email.split("@").first : nil) ||
      "user"

    safe_name = unique_name_for(base_name)

    create!(
      email:    email || "changeme+#{SecureRandom.hex(6)}@example.com",
      name:     safe_name,
      password: Devise.friendly_token[0, 20],
      provider: provider,
      uid:      uid
    )
  end

  class << self
    # 既存の Google 用エイリアス
    alias_method :from_google, :from_omniauth
    # LINE 用エイリアス（必要ならコールバック側で呼び分けに利用）
    alias_method :from_line, :from_omniauth
  end

  private

  def self.unique_name_for(base)
    name = base.to_s.gsub(/\s+/, "")
    return name unless exists?(name:)

    # 被りを避けるために連番/ランダムを付与
    1.upto(50) do |i|
      candidate = "#{name}_#{i}"
      return candidate unless exists?(name: candidate)
    end
    "#{name}_#{SecureRandom.hex(3)}"
  end

  def downcase_email
    self.email = email.to_s.downcase.presence
  end
end
