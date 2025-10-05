require "sso_openid/engine"
require "sso_openid/middleware"
require "sso_openid/paths"
require "sso_openid/urls"
require "omniauth/openid_connect"

module SsoOpenid
  autoload :SpecHelpers, 'sso_openid/spec_helpers'

  class Configuration

    def self.openid_options
      {
        client_options: {
          port: 443,
          scheme: "https",
          host: "dev-auth.dev.bonterralabs.io",  # Your custom domain host
          identifier: "MEWrh8cWedRRMFsyJQZ6HOEfuuiH8ikB",  # Your Client ID
          secret: "ZzdKZ7uctbp1ABbDHk3d8D1zTgmB-03YWVIhcQUwFtQgFOYV9u-8UXpt7odHvtXZ",  # Your Client Secret
        },
        callback_path: SsoOpenid::Paths.callback_path,
        request_path: SsoOpenid::Paths.auth_path,
        setup_path: SsoOpenid::Paths.setup_path,
        name: :sso_openid,
        discovery: true,
        issuer: "https://dev-auth.dev.bonterralabs.io/",  # Your custom domain (with trailing slash)
        setup: true,
        scope: [:openid, :email, :profile, :address],
      }
    end
  end
end
