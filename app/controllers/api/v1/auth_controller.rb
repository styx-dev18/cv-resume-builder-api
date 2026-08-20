module Api
  module V1
    class AuthController < BaseController
      include SessionIssuable

      before_action :authenticate_user!, only: [ :logout, :me ]

      def register
        user = User.new(register_params)

        if user.save
          issue_session_for(user, status: :created)
        else
          render_error(
            status: :unprocessable_content,
            code: "validation_failed",
            message: "Registration failed",
            details: user.errors.to_hash
          )
        end
      end

      def login
        user = User.find_by(email: login_params[:email]&.downcase)

        if user&.valid_password?(login_params[:password])
          issue_session_for(user)
        else
          render_error(status: :unauthorized, code: "invalid_credentials", message: "Invalid email or password")
        end
      end

      def refresh
        raw_token = cookies[REFRESH_COOKIE]
        refresh_token = RefreshToken.find_active_by_raw_token(raw_token)

        if refresh_token.nil?
          render_error(status: :unauthorized, code: "invalid_refresh_token", message: "Refresh token is invalid or expired")
          return
        end

        refresh_token.revoke!
        issue_session_for(refresh_token.user)
      end

      def logout
        raw_token = cookies[REFRESH_COOKIE]
        RefreshToken.find_active_by_raw_token(raw_token)&.revoke!
        current_user.update!(jti: User.generate_jti)

        clear_refresh_cookie
        head :no_content
      end

      def me
        render_data({ user: UserResource.new(current_user).as_json })
      end

      private

      def issue_session_for(user, status: :ok)
        result = issue_tokens_for(user)

        render_data(
          {
            access_token: result.access_token,
            access_token_expires_at: result.access_token_expires_at.iso8601,
            user: UserResource.new(user).as_json
          },
          status: status
        )
      end

      def register_params
        params.require(:user).permit(:email, :password, :name).tap do |p|
          p[:email] = p[:email]&.downcase
        end
      end

      def login_params
        params.require(:user).permit(:email, :password)
      end
    end
  end
end
