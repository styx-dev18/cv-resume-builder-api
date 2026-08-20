FactoryBot.define do
  factory :cv do
    user
    title { "My CV" }
    schema_version { 1 }
  end
end
