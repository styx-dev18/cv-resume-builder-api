class CvSummaryResource
  include Alba::Resource

  attributes :id

  attribute(:title) { |cv| cv.title.to_s }
  attribute(:createdAt) { |cv| cv.created_at.iso8601(3) }
  attribute(:updatedAt) { |cv| cv.updated_at.iso8601(3) }
end
