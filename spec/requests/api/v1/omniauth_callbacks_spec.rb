require "rails_helper"

RSpec.describe "Api::V1::OmniauthCallbacks", type: :request do
  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  def mock_google_auth(email:, name: "Google User", uid: "google-uid-123")
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(email: email, name: name)
    )
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
  end

  describe "GET /api/v1/auth/google_oauth2/callback" do
    it "creates a new user and redirects to the frontend with tokens" do
      mock_google_auth(email: "new-oauth@example.com")

      get "/api/v1/auth/google_oauth2/callback"

      expect(response).to have_http_status(:found)
      redirect_uri = URI.parse(response.headers["Location"])
      expect(redirect_uri.path).to eq("/auth/callback")

      params = Rack::Utils.parse_query(redirect_uri.query)
      expect(params["access_token"]).to be_present
      expect(params["access_token_expires_at"]).to be_present

      user = User.find_by(email: "new-oauth@example.com")
      expect(user).to be_present
      expect(user.provider).to eq("google_oauth2")
      expect(user.uid).to eq("google-uid-123")
    end

    it "reuses an existing user for the same provider/uid" do
      mock_google_auth(email: "repeat-oauth@example.com", uid: "repeat-uid")
      get "/api/v1/auth/google_oauth2/callback"
      first_user_id = User.find_by(uid: "repeat-uid").id

      mock_google_auth(email: "repeat-oauth@example.com", uid: "repeat-uid")
      get "/api/v1/auth/google_oauth2/callback"

      expect(User.where(uid: "repeat-uid").count).to eq(1)
      expect(User.find_by(uid: "repeat-uid").id).to eq(first_user_id)
    end

    it "redirects with an error when the email is already taken by a password account" do
      create(:user, email: "taken@example.com")
      mock_google_auth(email: "taken@example.com", uid: "some-other-uid")

      get "/api/v1/auth/google_oauth2/callback"

      redirect_uri = URI.parse(response.headers["Location"])
      params = Rack::Utils.parse_query(redirect_uri.query)
      expect(params["error"]).to eq("email_taken")
    end
  end
end
