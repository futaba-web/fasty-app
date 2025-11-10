# app/models/concerns/uidable.rb
module Uidable
  extend ActiveSupport::Concern

  included do
    before_validation :ensure_uid!, on: :create
    validates :uid, presence: true, uniqueness: true
  end

  # URL 表示用 ID を uid に変更 (BINARY16 → 32桁hex)
  def to_param
    uid.unpack1("H*")
  end

  private

  # DB は BINARY(16) なので、16バイトの乱数をそのまま持つ
  def ensure_uid!
    self.uid ||= SecureRandom.random_bytes(16)
  end

  module ClassMethods
    # URL の 32桁hex → BINARY(16) に変換して検索
    def find_by_uid_param!(hex)
      raise ActiveRecord::RecordNotFound unless hex&.match?(/\A\h{32}\z/)
      find_by!(uid: [hex].pack("H*"))
    end
  end
end
