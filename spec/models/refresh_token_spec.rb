require "rails_helper"

RSpec.describe RefreshToken, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe ".issue!" do
    it "creates a record and returns the raw token alongside it" do
      user = create(:user)

      raw_token, record = RefreshToken.issue!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")

      expect(record).to be_persisted
      expect(record.token_digest).to eq(RefreshToken.digest(raw_token))
      expect(record.expires_at).to be_within(1.second).of(RefreshToken::TTL.from_now)
    end
  end

  describe ".find_active_by_raw_token" do
    it "finds a matching, non-revoked, non-expired token" do
      raw_token, record = RefreshToken.issue!(user: create(:user))

      expect(RefreshToken.find_active_by_raw_token(raw_token)).to eq(record)
    end

    it "returns nil for a blank token" do
      expect(RefreshToken.find_active_by_raw_token(nil)).to be_nil
      expect(RefreshToken.find_active_by_raw_token("")).to be_nil
    end

    it "returns nil for a revoked token" do
      raw_token, record = RefreshToken.issue!(user: create(:user))
      record.revoke!

      expect(RefreshToken.find_active_by_raw_token(raw_token)).to be_nil
    end

    it "returns nil for an expired token" do
      raw_token, record = RefreshToken.issue!(user: create(:user))
      record.update!(expires_at: 1.minute.ago)

      expect(RefreshToken.find_active_by_raw_token(raw_token)).to be_nil
    end

    it "returns nil for an unknown token" do
      create(:user)

      expect(RefreshToken.find_active_by_raw_token("not-a-real-token")).to be_nil
    end
  end

  describe "#revoke!" do
    it "sets revoked_at" do
      token = create(:refresh_token)

      expect { token.revoke! }.to change { token.revoked_at }.from(nil)
    end
  end
end
