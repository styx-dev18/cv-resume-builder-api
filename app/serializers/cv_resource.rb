class CvResource
  include Alba::Resource

  attributes :id

  attribute(:title) { |cv| cv.title.to_s }
  attribute(:schemaVersion) { |cv| cv.schema_version }
  attribute(:createdAt) { |cv| cv.created_at.iso8601(3) }
  attribute(:updatedAt) { |cv| cv.updated_at.iso8601(3) }

  attribute :sections do |cv|
    cv.cv_sections.map do |section|
      {
        "id" => section.id,
        "type" => section.section_type,
        "title" => section.title.to_s,
        "items" => section.cv_section_items.map(&:as_json_fields)
      }
    end
  end
end
