require "json/jwt"

module SsoOpenid
  # (NFG-4485) Checks the `auth_time` claim of an ID token against a maximum age, per
  # https://auth0.com/docs/authenticate/login/max-age-reauthentication
  #
  # Reads the claim without verifying the signature: omniauth_openid_connect has already
  # verified the token (signature, issuer, audience, nonce, expiry) before the callback runs.
  module AuthFreshness
    # Tolerance for clock skew between this app and Auth0.
    LEEWAY = 60

    def self.fresh?(id_token, max_age, now: Time.now.to_i)
      auth_time = auth_time_from(id_token)
      !auth_time.nil? && now - auth_time <= max_age.to_i + LEEWAY
    end

    def self.auth_time_from(id_token)
      claims = JSON::JWT.decode(id_token.to_s, :skip_verification)
      Integer(claims[:auth_time], exception: false)
    rescue StandardError
      nil
    end
  end
end
