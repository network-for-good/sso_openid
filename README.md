# NfgOpenid

This gem provides a wrapper around omniauth and omniauth-openid-connect for handling authentication against NFG's OpenID identity server.

## Setup
1. `gem nfg_openid`
2. `bundle`
3. Mount the engine in your routes: `mount SsoOpenid::Engine => "/"`

## Modifications to the Admin model
1. Add a `self.from_omniauth(omniauth_data, subdomain, ip_address)` method to to handle user lookup and/or creation.
2. Optionally, you can add an instance method called `#restrict_access?` to encapsulate any necessary role-based evaluation.
3. If the admin record has a 'status' field, authentication will fail if it is set to anything other than 'active'.
4. The gem will expect the admins table to have a 'uid' field. The uid from the identity server should be stored in this field.

## Modifications to ApplicationController
1. Make sure you include `SsoOpenid::ApplicationHelper`.
2. Add a method called `sso_openid_after_sign_in_path`. This method should return the path to which signed in users should be redirected.
3. Add a method called `sso_openid_after_sign_out_path`. This method should return the path to which users should be redirected after signing out.
4. Add a method called `sso_openid_failure_path`. This is the path to where the user will be redirected upon any failure.
5. Add `before_filter authenticate_admin!`. Be sure to exclude this filter where necessary, such as in controller that handle the display of error messages to non-logged in users.

## Forcing periodic re-authentication (`max_auth_age`)
Auth0 keeps its own persistent session cookie and silently re-authenticates users whose app session has
expired. To require a credential prompt once a login is older than N seconds, set in the host app's
initializer:

    SsoOpenid.configure { |config| config.max_auth_age = 12.hours }

The gem then sends `max_age` to `/authorize` and checks the ID token's `auth_time` on the callback. Off
by default. See https://auth0.com/docs/authenticate/login/max-age-reauthentication

## Methods this gem provides
* `#authenticate_admin!` should run before each request to verify that a logged in admin exists. Otherwise, it will redirect to the auth path.
* `#current_admin` returns the logged in admin.
* `#sign_in(admin)` will sign in an admin by creating the admin_uid cookie.
* `#sign_out` will remove the cookie and redirect to the root path.
* `#stored_location` will return any path that the admin attempts to access before signing in.

## CI and Releasing

Every pull request against `main` runs the gem's RSpec suite via the [test workflow](.github/workflows/test.yml); a failing test blocks merge. (CircleCI also still runs on push/PR during the transition to GitHub Actions — it will be retired once the GitHub Actions workflow has a track record of passing builds.)

This gem doesn't follow strict semver — version numbers have historically tracked the supported Rails series, sometimes with ad hoc suffixes for in-progress work (e.g. `7.2.4.auth0.uat.1`, `7.3.2.beta1`). Whether a change warrants a release, and what the next version number should be, stays a judgment call made by the PR author, not something inferred from commit messages.

Releasing is automatic and merge-triggered — there's no local `gem push` step for a normal release:

1. As part of your PR, decide whether the change warrants a release, and if so, bump `lib/sso_openid/version.rb`.
2. On merge to `main`, the [publish-gem workflow](.github/workflows/publish-gem.yml) checks whether the current `VERSION` already has a matching `gem-v<version>` tag. If it does (i.e. the merge didn't change the version), it does nothing — no new package is published.
3. Otherwise it builds the gem, pushes it to the [network-for-good GitHub Packages registry](https://rubygems.pkg.github.com/network-for-good) using its own `GITHUB_TOKEN`, and pushes the `gem-v<version>` tag itself.

`bin/publish_gem` (what the workflow runs under the hood) also works for a manual/local release as a break-glass fallback — see the script for the required `~/.gem/credentials` entry — but it shouldn't be needed for normal releases.


