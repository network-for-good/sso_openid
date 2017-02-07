# NfgOpenid

This gem provides a wrapper around omniauth and omniauth-openid-connect for handling authentication against NFG's OpenID identity server.

## Setup
1. `gem nfg_openid`
2. `bundle`

## Modifications to the Admin model
1. Add a `self.from_omniauth(uid, subdomain)` method to to handle user lookup and/or creation.

## Modifications to ApplicationController
1. Make sure you include `SsoOpenid::ApplicationHelper`.
2. Add a method called `sso_openid_redirect_after_sign_in_oath`. This method should return the path to which signed in users should be redirected.
3. Add a method called `sso_openid_failure_path`. This is the path to where the user will be redirected upon any failure.
4. Add `before_filter authenticate_admin!`. Be sure to exclude this filter where necessary, such as in controller that handle the display of error messages to non-logged in users.

## Methods this gem provides
* `#authenticate_admin!` should run before each request to verify that a logged in admin exists. Otherwise, it will redirect to the auth path.
* `#current_admin` returns the logged in admin.
* `#sign_in(admin)` will sign in an admin by creating the admin_uid cookie.
* `#sign_out` will remove the cookie and redirect to the root path.
* `#stored_location` will return any path that the admin attempts to access before signing in.


