require "json/jwt"
require "faraday"

module SsoOpenid
  # Verifies Auth0 (bonterra-auth) RS256 JWTs the way bonterra-api-gateway does
  # (AUTHZ-ITD-008): the gateway validates the M2M access token and forwards it
  # unchanged, so the downstream service must independently re-verify it.
  #
  # Verification steps:
  #   1. Decode the token unverified to read its `iss` and header `kid`; reject
  #      unknown issuers.
  #   2. Resolve the issuer's JWKS via OIDC discovery
  #      (`<issuer>/.well-known/openid-configuration` -> `jwks_uri`), cached.
  #   3. Verify signature (RS256) against the matching JWK, then `iss`, `aud`,
  #      and expiry.
  #
  # Config is read from `SsoOpenid.configuration`:
  #   - issuers  : `jwt_issuers` if set, else derived from `discovery_endpoint`
  #                (with and without trailing slash, matching Auth0's `iss`).
  #   - audience : `jwt_audience` if set, else `host`.
  class Auth0JwtVerifier
    class VerificationError < StandardError; end

    JWKS_TTL_SECONDS  = 600
    DISCOVERY_TIMEOUT = 5

    class << self
      def default
        @default ||= from_config
      end

      def verify(token)
        default.verify(token)
      end

      # Test helper — drop the memoized default so config/JWKS caches reset.
      def reset!
        @default = nil
      end

      def from_config
        config = SsoOpenid.configuration || SsoOpenid::Configuration.new
        new(issuers: configured_issuers(config), audience: configured_audience(config))
      end

      private

      def configured_issuers(config)
        explicit = Array(config.jwt_issuers).map(&:to_s).reject(&:empty?)
        return explicit if explicit.any?

        discovery = config.discovery_endpoint.to_s
        return [] if discovery.empty?

        # Auth0's `iss` claim carries a trailing slash. Accept both forms defensively.
        base = discovery.delete_suffix("/")
        ["#{base}/", base]
      end

      def configured_audience(config)
        (config.jwt_audience.presence || config.host).to_s
      end
    end

    attr_reader :issuers, :audience

    def initialize(issuers:, audience:)
      @issuers    = Array(issuers).map(&:to_s).reject(&:empty?).uniq
      @audience   = audience.to_s
      @jwks_cache = {}
    end

    # Returns the verified payload (String-keyed Hash) or raises
    # VerificationError. Never makes a network call for tokens that aren't a
    # well-formed JWT for a known issuer.
    def verify(token)
      unverified = unverified_jwt(token)
      issuer = unverified[:iss].to_s
      raise VerificationError, "Unknown issuer: #{issuer.inspect}" unless @issuers.include?(issuer)
      raise VerificationError, "JWT audience is not configured" if @audience.empty?

      kid = unverified.header[:kid]
      key = jwk_for(issuer, kid)

      jwt = JSON::JWT.decode(token, key.to_key)
      verify_claims!(jwt, issuer)
      jwt.to_h.with_indifferent_access
    rescue JSON::JWT::InvalidFormat, JSON::JWS::VerificationFailed, JSON::JWK::Set::KidNotFound => e
      raise VerificationError, e.message
    end

    private

    def unverified_jwt(token)
      JSON::JWT.decode(token, :skip_verification)
    rescue JSON::JWT::InvalidFormat => e
      raise VerificationError, e.message
    end

    def verify_claims!(jwt, issuer)
      raise VerificationError, "Invalid issuer" unless jwt[:iss].to_s == issuer
      raise VerificationError, "Invalid audience" unless Array(jwt[:aud]).map(&:to_s).include?(@audience)
      raise VerificationError, "Token expired" if jwt[:exp] && jwt[:exp].to_i < Time.now.to_i
    end

    def jwk_for(issuer, kid)
      jwks = fetch_jwks(issuer)
      key = jwks[kid]
      return key if key

      # Key rotation: refetch once before giving up.
      jwks = fetch_jwks(issuer, force: true)
      jwks[kid] or raise JSON::JWK::Set::KidNotFound
    end

    def fetch_jwks(issuer, force: false)
      cached = @jwks_cache[issuer]
      return cached[:keys] if !force && cached && cached[:fetched_at] > monotonic_now - JWKS_TTL_SECONDS

      keys = load_jwks(issuer)
      @jwks_cache[issuer] = { keys: keys, fetched_at: monotonic_now }
      keys
    end

    # Resolve and fetch the issuer's JWKS via OIDC discovery.
    def load_jwks(issuer)
      jwks_uri = discover_jwks_uri(issuer)
      body = http_get_json(jwks_uri)
      raise VerificationError, "JWKS response missing keys" unless body.is_a?(Hash) && body["keys"]

      JSON::JWK::Set.new(body)
    end

    def discover_jwks_uri(issuer)
      base = issuer.delete_suffix("/")
      doc = http_get_json("#{base}/.well-known/openid-configuration")
      uri = doc.is_a?(Hash) ? doc["jwks_uri"] : nil
      raise VerificationError, "OIDC discovery missing jwks_uri for #{issuer}" if uri.to_s.empty?

      uri
    end

    def http_get_json(url)
      response = Faraday.get(url) { |req| req.options.timeout = DISCOVERY_TIMEOUT }
      raise VerificationError, "GET #{url} returned #{response.status}" unless response.status == 200

      JSON.parse(response.body)
    rescue Faraday::Error, JSON::ParserError => e
      raise VerificationError, "Failed to fetch #{url}: #{e.message}"
    end

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
