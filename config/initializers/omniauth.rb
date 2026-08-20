# devise_for :users, skip: :all means Devise never mounts its own
# /users/auth/* routes — point OmniAuth's Rack middleware at our
# hand-rolled Api::V1 auth namespace instead.
OmniAuth.config.path_prefix = "/api/v1/auth"

# The frontend triggers the request phase via a plain <a href> browser
# navigation (GET), not a POST carrying a Rails CSRF token. The installed
# omniauth-rails_csrf_protection gem defaults to POST-only for the request
# phase (mitigating login-CSRF per CVE-2015-9284); this restores GET.
# Risk is limited here since this flow only authenticates (it never links
# a provider to an already-signed-in account), and the callback itself is
# protected by OmniAuth's own session-backed `state` param.
OmniAuth.config.allowed_request_methods = [ :get ]
OmniAuth.config.silence_get_warning = true

Rails.application.config.to_prepare do
  OmniAuth.config.on_failure = Api::V1::OmniauthCallbacksController.action(:failure)
end
