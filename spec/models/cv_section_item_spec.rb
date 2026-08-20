require "rails_helper"

RSpec.describe CvSectionItem, type: :model do
  describe ".attributes_from_json / #as_json_fields round-trip" do
    it "round-trips the experience shape, mapping position -> job_title" do
      section = create(:cv_section, section_type: "experience")
      json = {
        "company" => "Acme", "position" => "Engineer", "location" => "Remote",
        "startDate" => "2020-01", "endDate" => "2022-01", "current" => false,
        "description" => "Built things"
      }

      item = section.cv_section_items.create!(CvSectionItem.attributes_from_json("experience", json))

      expect(item.job_title).to eq("Engineer")
      expect(item.as_json_fields).to eq(json.merge("id" => item.id))
    end

    it "round-trips the skills shape, mapping skills -> skills_text" do
      section = create(:cv_section, section_type: "skills")
      json = { "category" => "Languages", "skills" => "Ruby, TypeScript" }

      item = section.cv_section_items.create!(CvSectionItem.attributes_from_json("skills", json))

      expect(item.skills_text).to eq("Ruby, TypeScript")
      expect(item.as_json_fields).to eq(json.merge("id" => item.id))
    end

    it "serializes unset string fields as empty strings, not nil" do
      section = create(:cv_section, section_type: "summary")
      item = section.cv_section_items.create!(CvSectionItem.attributes_from_json("summary", {}))

      expect(item.as_json_fields).to eq({ "id" => item.id, "content" => "" })
    end

    it "only exposes the current fields relevant to the section's type" do
      section = create(:cv_section, section_type: "summary")
      item = section.cv_section_items.create!(content: "Hi")

      expect(item.as_json_fields.keys).to match_array(%w[id content])
    end
  end
end
