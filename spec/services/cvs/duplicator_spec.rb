require "rails_helper"

RSpec.describe Cvs::Duplicator do
  let(:user) { create(:user) }
  let(:cv) { create(:cv, user: user, title: "Original") }
  let!(:section) { create(:cv_section, cv: cv) }
  let!(:item) { create(:cv_section_item, cv_section: section) }

  it "deep-copies the cv, section, and item under fresh ids" do
    copy = described_class.call(source_cv: cv, new_title: nil)

    expect(copy.id).not_to eq(cv.id)
    expect(copy.user).to eq(user)
    expect(copy.cv_sections.sole.id).not_to eq(section.id)
    expect(copy.cv_sections.sole.cv_section_items.sole.id).not_to eq(item.id)
    expect(copy.cv_sections.sole.cv_section_items.sole.content).to eq(item.content)
  end

  it "does not mutate the source cv" do
    described_class.call(source_cv: cv, new_title: "Renamed")

    expect(cv.reload.title).to eq("Original")
  end

  it "defaults the title to '<original> (Copy)' when new_title is nil" do
    copy = described_class.call(source_cv: cv, new_title: nil)

    expect(copy.title).to eq("Original (Copy)")
  end

  it "honors an explicit title, including an explicit empty string" do
    expect(described_class.call(source_cv: cv, new_title: "Custom").title).to eq("Custom")
    expect(described_class.call(source_cv: cv, new_title: "").title).to eq("")
  end
end
