class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable, :omniauthable,
         jwt_revocation_strategy: self, omniauth_providers: %i[google_oauth2 github]

  enum :role, { user: 0, admin: 1 }

  has_many :refresh_tokens, dependent: :destroy
  has_many :cvs, dependent: :destroy

  validates :name, presence: true

  def self.from_omniauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
      user.email = auth.info.email
      user.name = auth.info.name.presence || auth.info.email
      user.password = Devise.friendly_token[0, 20]
    end
  end

  def jwt_payload
    super.merge("role" => role)
  end

  private

  def password_required?
    return false if provider.present?
    super
  end
end
