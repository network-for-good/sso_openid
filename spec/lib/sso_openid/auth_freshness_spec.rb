require 'rails_helper'

describe SsoOpenid::AuthFreshness do
  let(:now) { 1_800_000_000 }
  let(:max_age) { 12.hours.to_i }

  def token(claims)
    JSON::JWT.new(claims).to_s
  end

  describe ".fresh?" do
    it "accepts a login just inside the window" do
      expect(described_class.fresh?(token(auth_time: now - max_age + 1), max_age, now: now)).to be true
    end

    it "accepts a login slightly past the window, within clock-skew leeway" do
      expect(described_class.fresh?(token(auth_time: now - max_age - 30), max_age, now: now)).to be true
    end

    it "rejects a login older than the window plus leeway" do
      expect(described_class.fresh?(token(auth_time: now - max_age - 61), max_age, now: now)).to be false
    end

    it "rejects the 19h28m case from the pen test" do
      expect(described_class.fresh?(token(auth_time: now - (19.hours + 28.minutes).to_i), max_age, now: now)).to be false
    end

    it "rejects a token with no auth_time" do
      expect(described_class.fresh?(token(sub: 'abc'), max_age, now: now)).to be false
    end

    it "rejects a non-numeric auth_time" do
      expect(described_class.fresh?(token(auth_time: 'yesterday'), max_age, now: now)).to be false
    end

    it "rejects a token that is not a JWT" do
      expect(described_class.fresh?('asdf1234', max_age, now: now)).to be false
    end

    it "rejects a missing token" do
      expect(described_class.fresh?(nil, max_age, now: now)).to be false
    end

    it "accepts an ActiveSupport::Duration max age" do
      expect(described_class.fresh?(token(auth_time: now - 60), 12.hours, now: now)).to be true
    end
  end
end
