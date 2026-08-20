require "rails_helper"

RSpec.describe "Api::V1::Health", type: :request do
  describe "GET /api/v1/health" do
    it "returns ok status" do
      get "/api/v1/health"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["status"]).to eq("ok")
    end
  end
end
