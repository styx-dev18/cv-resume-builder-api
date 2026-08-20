class CvSection < ApplicationRecord
  SECTION_TYPES = %w[
    personalInfo summary experience education skills certifications
    languages projects publications awards references volunteering
  ].freeze

  belongs_to :cv
  has_many :cv_section_items, -> { order(:position) }, dependent: :destroy, inverse_of: :cv_section

  validates :section_type, presence: true, inclusion: { in: SECTION_TYPES }
end
