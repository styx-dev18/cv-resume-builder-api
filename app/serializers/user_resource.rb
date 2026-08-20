class UserResource
  include Alba::Resource

  attributes :id, :email, :name, :role, :created_at
end
