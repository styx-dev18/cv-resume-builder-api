class Cv < ApplicationRecord
  belongs_to :user

  has_many :cv_sections, -> { order(:position) }, dependent: :destroy, inverse_of: :cv
end
