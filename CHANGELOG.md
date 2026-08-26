# Changelog

All notable changes to sso_openid are documented here, one entry per release. Entry format
follows `specs/001-release-security-fix/contracts/release-changelog-entry.md`.

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
