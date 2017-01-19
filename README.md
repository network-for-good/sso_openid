# NfgOpenid

This gem provides a wrapper around omniauth and omniauth-openid-connect for handling authentication against NFG's OpenID identity server.

## Setup
1. `gem nfg_openid`
2. `bundle`
3. Add a `self.from_omniauth(uid, subdomain)` method to the Admin model to handle user lookup and/or creation.

