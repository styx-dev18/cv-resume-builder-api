class RefreshToken < ApplicationRecord
  belongs_to :user

  TOKEN_BYTES = 32
  TTL = 30.days

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.issue!(user:, user_agent: nil, ip_address: nil)
    raw_token = SecureRandom.urlsafe_base64(TOKEN_BYTES)
    record = create!(
      user: user,
      token_digest: digest(raw_token),
      expires_at: TTL.from_now,
      user_agent: user_agent,
      ip_address: ip_address
    )
    [ raw_token, record ]
  end

  def self.find_active_by_raw_token(raw_token)
    return nil if raw_token.blank?

    active.find_by(token_digest: digest(raw_token))
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def expired?
    expires_at <= Time.current
  end

  def revoked?
    revoked_at.present?
  end
end
