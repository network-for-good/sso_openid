require "sso_openid/engine"
require "sso_openid/middleware"
require "sso_openid/paths"
require "omniauth/openid_connect"

module SsoOpenid
  autoload :SpecHelpers, 'sso_openid/spec_helpers'

  class Configuration

    def self.openid_options
      {
        client_options: {
          port: 443,
          scheme: "https",
          host: APP_CONFIG[:sso_openid][:host],
          identifier: APP_CONFIG[:sso_openid][:client_id],
          secret: APP_CONFIG[:sso_openid][:client_secret],
        },
        callback_path: SsoOpenid::Paths.callback_path,
        request_path: SsoOpenid::Paths.auth_path,
        setup_path: SsoOpenid::Paths.setup_path,
        name: :sso_openid,
        discovery: true,
        issuer: APP_CONFIG[:sso_openid][:discovery_endpoint],
        setup: true,
        scope: [:openid, :email, :profile, :address],
      }
    end
  end
end
