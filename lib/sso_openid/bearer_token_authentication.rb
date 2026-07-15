module SsoOpenid
  # Layers Auth0 (bonterra-auth) JWT verification on top of a host app's
  # existing opaque-token bearer auth, matching the bonterra-api-gateway
  # pattern (AUTHZ-ITD-008): the gateway validates the forwarded M2M JWT and
  # the downstream service re-verifies it.
  #
  # Resolution order per request:
  #   1. Try to verify the bearer token as an Auth0 JWT (SsoOpenid::Auth0JwtVerifier).
  #   2. Otherwise fall back to the host app's existing opaque token path via
  #      `super`, which is expected to render its own 401s.
  #
  # Host apps include this in a concern that also includes their own opaque
  # bearer-token concern, so `super` resolves to that concern's
  # `authenticate_bearer_token!`. Example:
  #
  #   module Api::Auth::Auth0BearerTokenAuthentication
  #     extend ActiveSupport::Concern
  #     include Api::Auth::BearerTokenAuthentication
  #     include SsoOpenid::BearerTokenAuthentication
  #   end
  #
  # Note the include order: SsoOpenid::BearerTokenAuthentication must come
  # after the host concern so its `authenticate_bearer_token!` sits ahead of
  # the host's in the ancestor chain and `super` reaches the opaque path.
  module BearerTokenAuthentication
    extend ActiveSupport::Concern

    private

    def authenticate_bearer_token!
      token = extract_bearer_token
      # Let the opaque concern render the 401 for a missing token.
      return super if token.blank?

      payload = verify_auth0_jwt(token)
      # Not a valid Auth0 JWT — defer to the opaque path (existing 401 handling).
      return super if payload.nil?

      @current_token = token
      @current_token_payload = payload
      true
    end

    def verify_auth0_jwt(token)
      SsoOpenid::Auth0JwtVerifier.verify(token)
    rescue SsoOpenid::Auth0JwtVerifier::VerificationError
      nil
    end

    # JWT payloads expose scopes as `scope` (space-delimited string) or `scp`
    # (array) with string keys; opaque payloads typically use a `:scope`
    # symbol key. Normalize both, plus colon/dot scope notation.
    def token_scopes
      payload = current_token_payload || {}
      raw = payload["scope"] || payload[:scope] || payload["scp"] || payload[:scp]
      scopes = raw.is_a?(Array) ? raw : raw.to_s.split
      scopes.map { |scope| normalize_scope(scope) }
    end

    # Overrides the host concern's scope check (not just token_scopes) so a
    # normalized JWT scope can satisfy `required_scope`, but defers the actual
    # 403 rendering to `super` — the host app's existing response shape for
    # "insufficient scope" is a contract its other callers already depend on,
    # and this concern has no business changing it.
    def require_scope!(required_scope)
      return true if token_scopes.include?(normalize_scope(required_scope))

      super
    end

    # Reconcile the two scope vocabularies to one canonical form so a required
    # scope matches regardless of which auth path produced the token:
    #   - Opaque tokens issue colon-delimited scopes (`organizations:read`).
    #   - Auth0 (bonterra-auth) resource-server permissions are dot-delimited
    #     and namespaced under the gateway product prefix
    #     (`nfg:organizations.read`).
    # Both reduce to `organizations.read`: convert `:` to `.`, then drop a
    # leading product namespace.
    def normalize_scope(scope)
      scope.to_s.tr(":", ".").delete_prefix(product_scope_prefix)
    end

    # Product namespace the gateway/Auth0 flow prepends to every scope
    # (e.g. `nfg:organizations.read`). Override in the including controller
    # if a different product prefix applies.
    def product_scope_prefix
      "nfg."
    end
  end
end
