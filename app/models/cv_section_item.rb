class CvSectionItem < ApplicationRecord
  belongs_to :cv_section

  # Single source of truth for the JSON-key <-> DB-column mapping per
  # section type. Reused by both the write path (attributes_from_json,
  # used by Cvs::Upserter) and the read path (as_json_fields, used by
  # CvResource) so they can never drift apart.
  FIELD_MAP = {
    "personalInfo" => {
      "fullName" => :full_name, "location" => :location, "email" => :email,
      "phone" => :phone, "linkedin" => :linkedin, "github" => :github,
      "otherLink" => :other_link
    },
    "summary" => { "content" => :content },
    "experience" => {
      "company" => :company, "position" => :job_title, "location" => :location,
      "startDate" => :start_date, "endDate" => :end_date, "current" => :current,
      "description" => :description
    },
    "education" => {
      "school" => :school, "degree" => :degree, "honors" => :honors,
      "startDate" => :start_date, "endDate" => :end_date, "gpa" => :gpa
    },
    "skills" => { "category" => :category, "skills" => :skills_text },
    "certifications" => { "name" => :name, "date" => :date },
    "languages" => { "language" => :language, "proficiency" => :proficiency },
    "projects" => { "name" => :name, "link" => :link, "description" => :description },
    "publications" => {
      "title" => :title, "publisher" => :publisher, "date" => :date, "link" => :link
    },
    "awards" => {
      "title" => :title, "issuer" => :issuer, "date" => :date, "description" => :description
    },
    "references" => {
      "name" => :name, "relationship" => :relationship, "email" => :email, "phone" => :phone
    },
    "volunteering" => {
      "organization" => :organization, "role" => :role,
      "startDate" => :start_date, "endDate" => :end_date, "description" => :description
    }
  }.freeze

  # incoming JSON item params -> {db_column => value} for assign_attributes
  def self.attributes_from_json(section_type, item_params)
    FIELD_MAP.fetch(section_type, {}).each_with_object({}) do |(json_key, column), attrs|
      attrs[column] = item_params[json_key] if item_params.key?(json_key)
    end
  end

  # this row -> the frontend's flat item hash for its section's type
  def as_json_fields
    FIELD_MAP.fetch(cv_section.section_type, {}).each_with_object({ "id" => id }) do |(json_key, column), hash|
      value = self[column]
      hash[json_key] = column == :current ? !!value : value.to_s
    end
  end
end
