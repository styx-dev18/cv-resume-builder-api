FactoryBot.define do
  factory :cv_section_item do
    cv_section
    content { "Some content" }
    position { 0 }
  end
end
