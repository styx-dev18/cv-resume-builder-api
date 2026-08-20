FactoryBot.define do
  factory :cv_section do
    cv
    section_type { "summary" }
    title { "Summary" }
    position { 0 }
  end
end
