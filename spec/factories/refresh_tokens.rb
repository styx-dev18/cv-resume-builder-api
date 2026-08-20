FactoryBot.define do
  factory :refresh_token do
    user
    token_digest { RefreshToken.digest(SecureRandom.urlsafe_base64(32)) }
    expires_at { 30.days.from_now }
    revoked_at { nil }
    user_agent { "RSpec" }
    ip_address { "127.0.0.1" }
  end
end
