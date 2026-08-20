module Api
  module V1
    class OmniauthCallbacksController < BaseController
      include SessionIssuable

      def create
        auth = request.env["omniauth.auth"]
        user = User.from_omniauth(auth)

        if user.persisted?
          result = issue_tokens_for(user)
          redirect_to callback_url(
            access_token: result.access_token,
            access_token_expires_at: result.access_token_expires_at.iso8601
          ), allow_other_host: true
        else
          error_code = user.errors.of_kind?(:email, :taken) ? "email_taken" : "account_creation_failed"
          redirect_to callback_url(error: error_code), allow_other_host: true
        end
      end

      def failure
        redirect_to callback_url(error: params[:message] || "oauth_failed"), allow_other_host: true
      end

      private

      def callback_url(**query)
        "#{ENV.fetch('FRONTEND_ORIGIN', 'http://localhost:5173')}/auth/callback?#{query.to_query}"
      end
    end
  end
end
