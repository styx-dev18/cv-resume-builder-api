module Api
  module V1
    class BaseController < ActionController::API
      include Authenticatable

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable

      private

      def render_not_found(exception)
        render_error(status: :not_found, code: "not_found", message: exception.message)
      end

      def render_unprocessable(exception)
        render_error(
          status: :unprocessable_content,
          code: "validation_failed",
          message: exception.message,
          details: exception.record.errors.to_hash
        )
      end

      def render_error(status:, code:, message:, details: nil)
        render status: status, json: {
          error: { code: code, message: message, details: details }.compact
        }
      end

      def render_data(data, status: :ok)
        render status: status, json: { data: data }
      end
    end
  end
end
