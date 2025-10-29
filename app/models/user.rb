# app/models/user.rb
class User < ApplicationRecord
  # Devise
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  # Associations
  has_many :fasting_records, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true, length: { maximum: 30 }

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

  # ===== OmniAuth (Google) =====
  # OmniAuth の auth ハッシュからユーザーを取得/作成/紐付け
  #
  # 優先順位:
  # 1) provider + uid が一致するユーザー
  # 2) email が一致する既存ユーザーに provider / uid を付与
  # 3) 見つからなければ新規作成（name が無ければメールローカル部を代入）
  #
  def self.from_omniauth(auth)
    # ① すでに連携済みならそのまま返す
    if (user = find_by(provider: auth.provider, uid: auth.uid))
      return user
    end

    # ② 同じメールの既存ユーザーがいれば紐付け
    email = auth.info&.email
    if email && (user = find_by(email: email))
      user.update(provider: auth.provider, uid: auth.uid)
      return user
    end

    # ③ 新規作成
    name = auth.info&.name.presence ||
           auth.info&.first_name&.presence ||
           auth.info&.last_name&.presence ||
           (email ? email.split("@").first : "user_#{SecureRandom.hex(4)}")

    create!(
      email:    email || "changeme+#{SecureRandom.hex(6)}@example.com",
      name:     name,
      password: Devise.friendly_token[0, 20],
      provider: auth.provider,
      uid:      auth.uid
    )
  end
end
