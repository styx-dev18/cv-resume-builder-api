module Authenticatable
  extend ActiveSupport::Concern

  included do
    rescue_from Warden::JWTAuth::Errors::RevokedToken, with: :render_unauthorized
    rescue_from Warden::JWTAuth::Errors::NilUser, with: :render_unauthorized
    rescue_from Warden::JWTAuth::Errors::WrongScope, with: :render_unauthorized
    rescue_from Warden::JWTAuth::Errors::WrongAud, with: :render_unauthorized
    rescue_from JWT::DecodeError, with: :render_unauthorized
  end

  def authenticate_user!
    render_unauthorized unless current_user
  end

  def current_user
    @current_user ||= decode_current_user
  end

  private

  def decode_current_user
    token = bearer_token
    return nil if token.blank?

    Warden::JWTAuth::UserDecoder.new.call(token, :user, nil)
  end

  def bearer_token
    header = request.headers["Authorization"]
    return nil if header.blank?

    header.split(" ").last
  end

  def render_unauthorized(_exception = nil)
    render_error(status: :unauthorized, code: "unauthorized", message: "Authentication required")
  end
end
