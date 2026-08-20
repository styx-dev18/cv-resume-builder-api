module Auth
  # Issues a fresh access (JWT) + refresh (opaque) token pair for a user.
  # Uses the same Warden::JWTAuth encoder devise-jwt's automatic dispatch
  # uses, so access tokens here are revocable via the same JTI matcher.
  class TokenIssuer
    Result = Struct.new(:access_token, :access_token_expires_at, :refresh_token, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(user:, user_agent: nil, ip_address: nil)
      @user = user
      @user_agent = user_agent
      @ip_address = ip_address
    end

    def call
      user.update!(jti: User.generate_jti)

      access_token, = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
      raw_refresh_token, = RefreshToken.issue!(user: user, user_agent: user_agent, ip_address: ip_address)

      Result.new(
        access_token: access_token,
        access_token_expires_at: Time.current + Warden::JWTAuth.config.expiration_time,
        refresh_token: raw_refresh_token
      )
    end

    private

    attr_reader :user, :user_agent, :ip_address
  end
end
