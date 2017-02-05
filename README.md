# NfgOpenid

This gem provides a wrapper around omniauth and omniauth-openid-connect for handling authentication against NFG's OpenID identity server.

## Setup
1. `gem nfg_openid`
2. `bundle`

## Things you will need to provide
1. Add a `self.from_omniauth(uid, subdomain)` method to the Admin model to handle user lookup and/or creation.
2. Add a method to ApplicationController called `sso_openid_sign_in_and_redirect(admin)`. This method should handle the sign in logic.
3. Add a method to ApplicationController called `sso_openid_failure_path`. This is the path to where the user will be redirected upon any failure.


