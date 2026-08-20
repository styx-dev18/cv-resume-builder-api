require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/auth/register" do
    let(:valid_params) do
      { user: { email: "new@example.com", password: "password123", name: "New User" } }
    end

    it "creates a user and returns tokens" do
      post "/api/v1/auth/register", params: valid_params

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["access_token"]).to be_present
      expect(body["data"]["user"]["email"]).to eq("new@example.com")
      expect(User.find_by(email: "new@example.com")).to be_present
    end

    it "sets an httpOnly refresh_token cookie" do
      post "/api/v1/auth/register", params: valid_params

      set_cookie = response.headers["Set-Cookie"].downcase
      expect(set_cookie).to include("refresh_token=")
      expect(set_cookie).to include("httponly")
      expect(set_cookie).to include("samesite=strict")
    end

    it "rejects duplicate emails" do
      create(:user, email: "dup@example.com")

      post "/api/v1/auth/register", params: { user: { email: "dup@example.com", password: "password123", name: "Dup" } }

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["error"]["details"]).to have_key("email")
    end

    it "rejects a too-short password" do
      post "/api/v1/auth/register", params: { user: { email: "x@example.com", password: "short", name: "X" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "login@example.com", password: "password123") }

    it "logs in with valid credentials" do
      post "/api/v1/auth/login", params: { user: { email: "login@example.com", password: "password123" } }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["access_token"]).to be_present
      expect(body["data"]["user"]["id"]).to eq(user.id)
    end

    it "is case-insensitive on email" do
      post "/api/v1/auth/login", params: { user: { email: "LOGIN@EXAMPLE.COM", password: "password123" } }

      expect(response).to have_http_status(:ok)
    end

    it "rejects an invalid password" do
      post "/api/v1/auth/login", params: { user: { email: "login@example.com", password: "wrong" } }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects an unknown email" do
      post "/api/v1/auth/login", params: { user: { email: "nobody@example.com", password: "password123" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/auth/refresh" do
    let!(:user) { create(:user) }

    def login_and_extract_cookie
      post "/api/v1/auth/login", params: { user: { email: user.email, password: "password123" } }
      response.cookies["refresh_token"]
    end

    it "issues a new token pair and rotates the refresh token" do
      raw_refresh_token = login_and_extract_cookie
      old_record = RefreshToken.find_active_by_raw_token(raw_refresh_token)

      cookies["refresh_token"] = raw_refresh_token
      post "/api/v1/auth/refresh"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["access_token"]).to be_present
      expect(old_record.reload).to be_revoked
      expect(response.cookies["refresh_token"]).not_to eq(raw_refresh_token)
    end

    it "rejects a missing refresh token" do
      post "/api/v1/auth/refresh"

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects an already-revoked refresh token" do
      raw_refresh_token = login_and_extract_cookie
      RefreshToken.find_active_by_raw_token(raw_refresh_token).revoke!

      cookies["refresh_token"] = raw_refresh_token
      post "/api/v1/auth/refresh"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/me" do
    let!(:user) { create(:user) }

    it "returns the current user for a valid access token" do
      post "/api/v1/auth/login", params: { user: { email: user.email, password: "password123" } }
      access_token = JSON.parse(response.body)["data"]["access_token"]

      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{access_token}" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["user"]["id"]).to eq(user.id)
    end

    it "requires authentication" do
      get "/api/v1/auth/me"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    let!(:user) { create(:user) }

    it "revokes the refresh token and rotates the user's jti" do
      post "/api/v1/auth/login", params: { user: { email: user.email, password: "password123" } }
      login_body = JSON.parse(response.body)
      access_token = login_body["data"]["access_token"]
      access_token_jti = JWT.decode(access_token, nil, false).first["jti"]
      raw_refresh_token = response.cookies["refresh_token"]

      cookies["refresh_token"] = raw_refresh_token
      delete "/api/v1/auth/logout", headers: { "Authorization" => "Bearer #{access_token}" }

      expect(response).to have_http_status(:no_content)
      expect(RefreshToken.find_active_by_raw_token(raw_refresh_token)).to be_nil
      expect(user.reload.jti).not_to eq(access_token_jti)
    end

    it "requires authentication" do
      delete "/api/v1/auth/logout"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
