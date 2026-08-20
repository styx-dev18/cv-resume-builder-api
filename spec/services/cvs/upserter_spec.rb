require "rails_helper"

RSpec.describe Cvs::Upserter do
  let(:user) { create(:user) }
  let(:cv_id) { SecureRandom.uuid }
  let(:section_id) { SecureRandom.uuid }
  let(:item_id) { SecureRandom.uuid }

  let(:params) do
    ActionController::Parameters.new(
      title: "My CV",
      schemaVersion: 1,
      sections: [
        {
          id: section_id,
          type: "summary",
          title: "Summary",
          items: [ { id: item_id, content: "Hello" } ]
        }
      ]
    ).permit(:title, :schemaVersion, sections: [ :id, :type, :title, items: [ :id, :content ] ])
  end

  it "creates the cv, section, and item on first call" do
    cv = described_class.call(user: user, cv_id: cv_id, params: params)

    expect(cv.id).to eq(cv_id)
    expect(cv.title).to eq("My CV")
    expect(cv.cv_sections.sole.id).to eq(section_id)
    expect(cv.cv_sections.sole.cv_section_items.sole.content).to eq("Hello")
  end

  it "updates in place on a second call with the same ids" do
    described_class.call(user: user, cv_id: cv_id, params: params)

    updated_params = ActionController::Parameters.new(
      title: "My CV",
      schemaVersion: 1,
      sections: [
        { id: section_id, type: "summary", title: "Summary", items: [ { id: item_id, content: "Updated" } ] }
      ]
    ).permit(:title, :schemaVersion, sections: [ :id, :type, :title, items: [ :id, :content ] ])

    expect {
      described_class.call(user: user, cv_id: cv_id, params: updated_params)
    }.to change(CvSectionItem, :count).by(0)

    expect(CvSectionItem.find(item_id).content).to eq("Updated")
  end

  it "removes sections/items dropped from the payload" do
    described_class.call(user: user, cv_id: cv_id, params: params)

    empty_params = ActionController::Parameters.new(title: "My CV", schemaVersion: 1, sections: [])
      .permit(:title, :schemaVersion, sections: [])

    described_class.call(user: user, cv_id: cv_id, params: empty_params)

    expect(CvSection.where(id: section_id)).not_to exist
    expect(CvSectionItem.where(id: item_id)).not_to exist
  end
end
