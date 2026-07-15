require "rails_helper"

describe SsoOpenid::Auth0JwtVerifier do
  let(:issuer) { "https://bonterra-auth.example.com/" }
  let(:audience) { "https://dm.networkforgood.com" }
  let(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:kid) { "test-key-1" }
  let(:jwk) { JSON::JWK.new(rsa_key.public_key, kid: kid, use: "sig", alg: "RS256") }
  let(:jwks_body) { { keys: [jwk] }.to_json }
  let(:discovery_body) do
    { issuer: issuer, jwks_uri: "#{issuer.delete_suffix('/')}/.well-known/jwks.json" }.to_json
  end

  subject(:verifier) { described_class.new(issuers: [issuer], audience: audience) }

  def build_token(claims = {})
    payload = {
      iss: issuer,
      aud: audience,
      exp: 1.hour.from_now.to_i,
      scope: "nfg:organizations.read",
    }.merge(claims)

    jwt = JSON::JWT.new(payload)
    jwt.kid = kid
    jwt.sign(rsa_key, :RS256).to_s
  end

  def stub_discovery_and_jwks
    stub_request(:get, "#{issuer.delete_suffix('/')}/.well-known/openid-configuration")
      .to_return(status: 200, body: discovery_body, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "#{issuer.delete_suffix('/')}/.well-known/jwks.json")
      .to_return(status: 200, body: jwks_body, headers: { "Content-Type" => "application/json" })
  end

  describe "#verify" do
    context "with a valid token" do
      before { stub_discovery_and_jwks }

      it "returns the verified payload" do
        payload = verifier.verify(build_token)
        expect(payload["iss"]).to eq(issuer)
        expect(payload["scope"]).to eq("nfg:organizations.read")
      end

      it "caches the JWKS across calls" do
        verifier.verify(build_token)
        verifier.verify(build_token)
        expect(WebMock).to have_requested(:get, "#{issuer.delete_suffix('/')}/.well-known/jwks.json").once
      end
    end

    context "with an unknown issuer" do
      it "raises VerificationError without making a network call" do
        token = JSON::JWT.new(iss: "https://evil.example.com/", aud: audience, exp: 1.hour.from_now.to_i)
                          .sign(rsa_key, :RS256).to_s
        expect { verifier.verify(token) }.to raise_error(described_class::VerificationError, /Unknown issuer/)
        expect(WebMock).not_to have_requested(:get, /jwks/)
      end
    end

    context "with the wrong audience" do
      before { stub_discovery_and_jwks }

      it "raises VerificationError" do
        token = build_token(aud: "https://someone-else.example.com")
        expect { verifier.verify(token) }.to raise_error(described_class::VerificationError, /audience/i)
      end
    end

    context "with an expired token" do
      before { stub_discovery_and_jwks }

      it "raises VerificationError" do
        token = build_token(exp: 1.hour.ago.to_i)
        expect { verifier.verify(token) }.to raise_error(described_class::VerificationError, /expired/i)
      end
    end

    context "with a bad signature" do
      before { stub_discovery_and_jwks }

      it "raises VerificationError" do
        other_key = OpenSSL::PKey::RSA.generate(2048)
        jwt = JSON::JWT.new(iss: issuer, aud: audience, exp: 1.hour.from_now.to_i)
        jwt.kid = kid
        token = jwt.sign(other_key, :RS256).to_s

        expect { verifier.verify(token) }.to raise_error(described_class::VerificationError)
      end
    end

    context "when the signing key has rotated" do
      it "refetches the JWKS once and verifies against the new key" do
        stale_key = OpenSSL::PKey::RSA.generate(2048)
        stale_jwk = JSON::JWK.new(stale_key.public_key, kid: "old-key", use: "sig", alg: "RS256")

        stub_request(:get, "#{issuer.delete_suffix('/')}/.well-known/openid-configuration")
          .to_return(status: 200, body: discovery_body, headers: { "Content-Type" => "application/json" })
        stub_request(:get, "#{issuer.delete_suffix('/')}/.well-known/jwks.json")
          .to_return(
            { status: 200, body: { keys: [stale_jwk] }.to_json, headers: { "Content-Type" => "application/json" } },
            { status: 200, body: jwks_body, headers: { "Content-Type" => "application/json" } },
          )

        expect(verifier.verify(build_token)["iss"]).to eq(issuer)
        expect(WebMock).to have_requested(:get, "#{issuer.delete_suffix('/')}/.well-known/jwks.json").twice
      end
    end

    context "when JWKS response is missing keys" do
      before do
        stub_request(:get, "#{issuer.delete_suffix('/')}/.well-known/openid-configuration")
          .to_return(status: 200, body: discovery_body, headers: { "Content-Type" => "application/json" })
        stub_request(:get, "#{issuer.delete_suffix('/')}/.well-known/jwks.json")
          .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "raises VerificationError" do
        expect { verifier.verify(build_token) }.to raise_error(described_class::VerificationError, /missing keys/)
      end
    end
  end

  describe ".from_config" do
    after { SsoOpenid.configuration = nil }

    it "derives issuers from discovery_endpoint when jwt_issuers is unset" do
      SsoOpenid.configure do |config|
        config.discovery_endpoint = "https://bonterra-auth.example.com"
        config.host = "https://dm.networkforgood.com"
      end

      instance = described_class.from_config
      expect(instance.issuers).to contain_exactly(
        "https://bonterra-auth.example.com/",
        "https://bonterra-auth.example.com",
      )
      expect(instance.audience).to eq("https://dm.networkforgood.com")
    end

    it "prefers explicit jwt_issuers and jwt_audience when set" do
      SsoOpenid.configure do |config|
        config.discovery_endpoint = "https://bonterra-auth.example.com"
        config.host = "https://dm.networkforgood.com"
        config.jwt_issuers = ["https://custom-issuer.example.com/"]
        config.jwt_audience = "custom-audience"
      end

      instance = described_class.from_config
      expect(instance.issuers).to eq(["https://custom-issuer.example.com/"])
      expect(instance.audience).to eq("custom-audience")
    end
  end
end
