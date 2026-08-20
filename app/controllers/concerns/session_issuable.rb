module SessionIssuable
  extend ActiveSupport::Concern

  REFRESH_COOKIE = :refresh_token

  included do
    include ActionController::Cookies
  end

  private

  def issue_tokens_for(user)
    result = Auth::TokenIssuer.call(user: user, user_agent: request.user_agent, ip_address: request.remote_ip)
    set_refresh_cookie(result.refresh_token)
    result
  end

  def set_refresh_cookie(raw_token)
    cookies[REFRESH_COOKIE] = { value: raw_token, expires: RefreshToken::TTL.from_now, **refresh_cookie_options }
  end

  def clear_refresh_cookie
    cookies.delete(REFRESH_COOKIE, **refresh_cookie_options.slice(:path, :domain))
  end

  def refresh_cookie_options
    {
      httponly: true,
      secure: Rails.env.production?,
      same_site: :strict,
      path: "/api/v1/auth"
    }
  end
end
