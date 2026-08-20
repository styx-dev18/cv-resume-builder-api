require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe "associations" do
    it { is_expected.to have_many(:refresh_tokens).dependent(:destroy) }
  end

  describe "#jwt_payload" do
    it "includes the jti and role claims" do
      user = create(:user, role: :admin)

      expect(user.jwt_payload).to eq("jti" => user.jti, "role" => "admin")
    end
  end

  it "assigns a jti on create" do
    user = create(:user)

    expect(user.jti).to be_present
  end
end
