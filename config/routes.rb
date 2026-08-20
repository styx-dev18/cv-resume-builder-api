Rails.application.routes.draw do
  # Registers the :user Warden scope/mapping (Devise.mappings) that
  # Warden::JWTAuth relies on to decode tokens back into a User. Our
  # actual auth endpoints are hand-rolled below, not Devise's own routes.
  devise_for :users, skip: :all

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"

      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/refresh", to: "auth#refresh"
      delete "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"

      # Request-phase paths (GET /api/v1/auth/google_oauth2, /github) are
      # intercepted directly by the OmniAuth Rack middleware (see
      # config/initializers/omniauth.rb's path_prefix) and never reach here.
      get "auth/:provider/callback", to: "omniauth_callbacks#create"

      resources :cvs, only: [ :index, :show, :update, :destroy ] do
        member do
          post :duplicate
          get :pdf
        end
      end
    end
  end
end
