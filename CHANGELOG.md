# Changelog

All notable changes to sso_openid are documented here, one entry per release. Entry format
follows `specs/001-release-security-fix/contracts/release-changelog-entry.md`.

## [v7.3.3] - 2026-08-26

### Security
- Supersedes `v7.3.2`: a `bundle-audit` scan against `v7.3.2` found it still resolved Rails to
  `7.2.2.1` (not the `7.2.3.1`+ target NFG-3893 called for), leaving ~22 of NFG-3645's tracked
  CVEs present plus ~35 CVEs not on that list at all. This release bumps dependencies and
  re-verifies.
- Resolved (per `bundle-audit`, Ruby Advisory DB, run against this tag): all of NFG-3645's
  tracked CVEs that have an available fix, via `rails` `7.2.2.1` → `7.2.3.2` (clears
  `CVE-2026-33195`, `CVE-2026-33174`, `CVE-2026-66066`, `CVE-2026-34785`, `CVE-2026-34829`,
  `CVE-2026-34830`, `CVE-2026-54904`, `CVE-2026-61666`, and others in the same Rails point-release
  train) plus the ~35 CVEs newly surfaced by the `v7.3.2` scan (via transitive bumps to
  `nokogiri`, `rack`-adjacent gems, `websocket-driver`, `rails-html-sanitizer`, `loofah`,
  `net-imap`, etc., and a dev-only `sqlite3` `1.7.3` → `2.9.6` bump — `sqlite3` is a test-only
  dependency and does not affect consumer apps).
- Risk-accepted: `CVE-2015-9284` (`omniauth` CSRF, GHSA-ww4x-rwq6-qpgf) — already on NFG-3645's
  list. Fix requires `omniauth` `2.0.0`, a breaking change to the OmniAuth request-phase
  behavior (POST-only by default) affecting every consumer app's sign-in flow. That's a separate
  migration project, not a patch bump — tracked as follow-up, not blocking this release.
- Verification method: `bundle-audit` (Ruby Advisory DB) was used, not Snyk (no Snyk
  CLI/dashboard access was available). Re-run the org's Snyk scan against this tag when
  possible to cross-check.
- Full local test suite (79 examples) passes against the updated dependency set.

### Added
- Auth0 JWT verifier (NFG-3957) — reusable Auth0 JWT verification, including multi-tenant M2M
  token acceptance. (Carried over from `v7.3.2`.)

### Excluded
- Multi-issuer JWT verification (NFG-4177) — still in progress on the `uat` branch
  (version `7.3.2.beta1`); ships in a later release.

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
