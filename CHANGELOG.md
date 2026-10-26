# Changelog

All notable changes to sso_openid are documented here, one entry per release. Entry format
follows `specs/001-release-security-fix/contracts/release-changelog-entry.md`.

## [v7.3.4] - 2026-10-26

### Security
- NFG-4485: opt-in `SsoOpenid.configuration.max_auth_age` (seconds or an ActiveSupport::Duration).
  When set, `/authorize` is sent `max_age`, and the callback rejects an ID token whose `auth_time`
  is missing or older than `max_auth_age` (plus 60s of clock-skew leeway), sending the user through
  Auth0 logout back to the login screen so credentials are required. Default `nil`: no behavior
  change for apps that do not set it. See
  https://auth0.com/docs/authenticate/login/max-age-reauthentication

### Changed
- `SpecHelpers#sso_openid_omniauth_stub_for` now mints an unsigned JWT `id_token` carrying
  `auth_time` (new optional `auth_time:` keyword, default now) instead of the literal string
  `'asdf1234'`, so host apps that enable `max_auth_age` can still sign in under test.

## [v7.3.2] - 2026-08-26

### Security
- Includes the Rails 7.2.3.1 upgrade and dependency remediation merged for NFG-3645 (see that
  ticket for the full CVE list this was intended to address).
- **Verification status: not scanned.** A fresh dependency-vulnerability scan against this exact
  tag has **not** been run (no Snyk access was available at release time). This means neither
  "all NFG-3645 CVEs resolved" nor a documented risk-acceptance list can be asserted for this
  specific tag — that verification is outstanding. Run a scan against `v7.3.2` before treating
  this release as security-verified; see NFG-3645/NFG-3893 for the CVE list to check against.

### Added
- Auth0 JWT verifier (NFG-3957) — reusable Auth0 JWT verification, including multi-tenant M2M
  token acceptance.

### Excluded
- Multi-issuer JWT verification (NFG-4177) — still in progress on the `uat` branch
  (version `7.3.2.beta1`); ships in a later release.
