require "rails_helper"

RSpec.describe "Api::V1::Cvs", type: :request do
  let!(:user) { create(:user, password: "password123") }
  let!(:other_user) { create(:user, password: "password123") }

  def auth_headers_for(target_user)
    post "/api/v1/auth/login", params: { user: { email: target_user.email, password: "password123" } }
    access_token = JSON.parse(response.body)["data"]["access_token"]
    { "Authorization" => "Bearer #{access_token}" }
  end

  let(:headers) { auth_headers_for(user) }

  describe "GET /api/v1/cvs" do
    it "requires authentication" do
      get "/api/v1/cvs"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns only the current user's CVs, ordered by updated_at desc" do
      older = create(:cv, user: user, title: "Older", updated_at: 2.days.ago)
      newer = create(:cv, user: user, title: "Newer", updated_at: 1.hour.ago)
      create(:cv, user: other_user, title: "Not mine")

      get "/api/v1/cvs", headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |cv| cv["id"] }).to eq([ newer.id, older.id ])
      expect(body["data"].first.keys).to match_array(%w[id title createdAt updatedAt])
    end
  end

  describe "GET /api/v1/cvs/:id" do
    it "requires authentication" do
      cv = create(:cv, user: user)

      get "/api/v1/cvs/#{cv.id}"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the full nested shape with camelCase keys per section type" do
      cv = create(:cv, user: user, title: "My CV")
      section = create(:cv_section, cv: cv, section_type: "experience", title: "Work", position: 0)
      create(:cv_section_item, cv_section: section, position: 0,
        company: "Acme", job_title: "Engineer", location: "Remote",
        start_date: "2020-01", end_date: "", current: true, description: "Did stuff")

      get "/api/v1/cvs/#{cv.id}", headers: headers

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)["data"]
      expect(data["id"]).to eq(cv.id)
      expect(data["title"]).to eq("My CV")
      section_json = data["sections"].first
      expect(section_json["type"]).to eq("experience")
      item_json = section_json["items"].first
      expect(item_json).to include(
        "company" => "Acme", "position" => "Engineer", "location" => "Remote",
        "startDate" => "2020-01", "endDate" => "", "current" => true, "description" => "Did stuff"
      )
    end

    it "returns 404 for another user's CV" do
      cv = create(:cv, user: other_user)

      get "/api/v1/cvs/#{cv.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a malformed id" do
      get "/api/v1/cvs/not-a-uuid", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT /api/v1/cvs/:id" do
    let(:cv_id) { SecureRandom.uuid }
    let(:section_id) { SecureRandom.uuid }
    let(:item_id) { SecureRandom.uuid }

    let(:payload) do
      {
        cv: {
          title: "New CV",
          schemaVersion: 1,
          sections: [
            {
              id: section_id,
              type: "experience",
              title: "Work",
              items: [
                {
                  id: item_id,
                  company: "Acme",
                  position: "Engineer",
                  location: "Remote",
                  startDate: "2020-01",
                  endDate: "",
                  current: true,
                  description: "Did stuff"
                }
              ]
            }
          ]
        }
      }
    end

    it "requires authentication" do
      put "/api/v1/cvs/#{cv_id}", params: payload

      expect(response).to have_http_status(:unauthorized)
    end

    it "creates the CV, section, and item on first save (upsert)" do
      expect {
        put "/api/v1/cvs/#{cv_id}", params: payload, headers: headers
      }.to change(Cv, :count).by(1).and change(CvSection, :count).by(1).and change(CvSectionItem, :count).by(1)

      expect(response).to have_http_status(:ok)
      cv = Cv.find(cv_id)
      expect(cv.user).to eq(user)
      expect(cv.title).to eq("New CV")

      body = JSON.parse(response.body)["data"]
      expect(body["sections"].first["items"].first["company"]).to eq("Acme")
    end

    it "updates fields in place on a second save with the same ids (no new rows)" do
      put "/api/v1/cvs/#{cv_id}", params: payload, headers: headers

      updated_payload = payload.deep_dup
      updated_payload[:cv][:sections][0][:items][0][:company] = "Globex"

      expect {
        put "/api/v1/cvs/#{cv_id}", params: updated_payload, headers: headers
      }.to change(Cv, :count).by(0).and change(CvSection, :count).by(0).and change(CvSectionItem, :count).by(0)

      expect(CvSectionItem.find(item_id).company).to eq("Globex")
    end

    it "removes sections/items dropped from the payload" do
      put "/api/v1/cvs/#{cv_id}", params: payload, headers: headers

      empty_payload = { cv: { title: "New CV", schemaVersion: 1, sections: [] } }
      put "/api/v1/cvs/#{cv_id}", params: empty_payload, headers: headers

      expect(response).to have_http_status(:ok)
      expect(CvSection.where(id: section_id)).not_to exist
      expect(CvSectionItem.where(id: item_id)).not_to exist
    end

    it "reorders items according to array order" do
      second_item_id = SecureRandom.uuid
      two_item_payload = payload.deep_dup
      two_item_payload[:cv][:sections][0][:items] << {
        id: second_item_id, company: "Second", position: "Dev", location: "", startDate: "", endDate: "", current: false, description: ""
      }
      put "/api/v1/cvs/#{cv_id}", params: two_item_payload, headers: headers

      reordered_payload = two_item_payload.deep_dup
      reordered_payload[:cv][:sections][0][:items].reverse!
      put "/api/v1/cvs/#{cv_id}", params: reordered_payload, headers: headers

      get "/api/v1/cvs/#{cv_id}", headers: headers
      items = JSON.parse(response.body)["data"]["sections"].first["items"]
      expect(items.map { |i| i["id"] }).to eq([ second_item_id, item_id ])
    end

    it "returns 404 for a malformed id" do
      put "/api/v1/cvs/not-a-uuid", params: payload, headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 409 and leaves another user's CV of the same id untouched" do
      existing = create(:cv, user: other_user, id: cv_id, title: "Other's CV")

      put "/api/v1/cvs/#{cv_id}", params: payload, headers: headers

      expect(response).to have_http_status(:conflict)
      expect(existing.reload.title).to eq("Other's CV")
    end
  end

  describe "DELETE /api/v1/cvs/:id" do
    it "requires authentication" do
      cv = create(:cv, user: user)

      delete "/api/v1/cvs/#{cv.id}"

      expect(response).to have_http_status(:unauthorized)
    end

    it "deletes the CV and cascades to sections/items" do
      cv = create(:cv, user: user)
      section = create(:cv_section, cv: cv)
      create(:cv_section_item, cv_section: section)

      expect {
        delete "/api/v1/cvs/#{cv.id}", headers: headers
      }.to change(Cv, :count).by(-1).and change(CvSection, :count).by(-1).and change(CvSectionItem, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for another user's CV" do
      cv = create(:cv, user: other_user)

      delete "/api/v1/cvs/#{cv.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a malformed id" do
      delete "/api/v1/cvs/not-a-uuid", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/cvs/:id/duplicate" do
    it "requires authentication" do
      cv = create(:cv, user: user)

      post "/api/v1/cvs/#{cv.id}/duplicate"

      expect(response).to have_http_status(:unauthorized)
    end

    it "creates a deep copy with fresh ids at all 3 levels and a default title" do
      cv = create(:cv, user: user, title: "Original")
      section = create(:cv_section, cv: cv)
      item = create(:cv_section_item, cv_section: section)

      expect {
        post "/api/v1/cvs/#{cv.id}/duplicate", headers: headers
      }.to change(Cv, :count).by(1).and change(CvSection, :count).by(1).and change(CvSectionItem, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)["data"]
      expect(body["id"]).not_to eq(cv.id)
      expect(body["title"]).to eq("Original (Copy)")
      expect(body["sections"].first["id"]).not_to eq(section.id)
      expect(body["sections"].first["items"].first["id"]).not_to eq(item.id)
    end

    it "honors an explicit title, including an explicit empty string" do
      cv = create(:cv, user: user, title: "Original")

      post "/api/v1/cvs/#{cv.id}/duplicate", params: { title: "Custom" }, headers: headers
      expect(JSON.parse(response.body)["data"]["title"]).to eq("Custom")

      post "/api/v1/cvs/#{cv.id}/duplicate", params: { title: "" }, headers: headers
      expect(JSON.parse(response.body)["data"]["title"]).to eq("")
    end

    it "returns 404 for another user's CV" do
      cv = create(:cv, user: other_user)

      post "/api/v1/cvs/#{cv.id}/duplicate", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/cvs/:id/pdf" do
    it "requires authentication" do
      cv = create(:cv, user: user)

      get "/api/v1/cvs/#{cv.id}/pdf"

      expect(response).to have_http_status(:unauthorized)
    end

    it "streams the rendered PDF as an attachment" do
      cv = create(:cv, user: user, title: "My CV")
      allow(Cvs::PdfRenderer).to receive(:call).with(cv: cv).and_return("%PDF-1.7 fake bytes")

      get "/api/v1/cvs/#{cv.id}/pdf", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("attachment", "My CV.pdf")
      expect(response.body).to eq("%PDF-1.7 fake bytes")
    end

    it "returns 404 for another user's CV" do
      cv = create(:cv, user: other_user)

      get "/api/v1/cvs/#{cv.id}/pdf", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
