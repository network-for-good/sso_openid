require "sso_openid/engine"
require "sso_openid/middleware"
require "sso_openid/paths"
require "sso_openid/urls"
require "omniauth/openid_connect"

module SsoOpenid
  autoload :SpecHelpers, 'sso_openid/spec_helpers'

  class Configuration

    def self.openid_options
      # Read configuration from APP_CONFIG (api-keys.yml)
      sso_config = APP_CONFIG[:sso_openid]
      
      {
        client_options: {
          port: 443,
          scheme: "https",
          host: SsoOpenid::Urls.sso_openid.host,
          identifier: sso_config[:client_id],
          secret: sso_config[:client_secret],
        },
        callback_path: SsoOpenid::Paths.callback_path,
        request_path: SsoOpenid::Paths.auth_path,
        setup_path: SsoOpenid::Paths.setup_path,
        name: :sso_openid,
        discovery: true,
        issuer: SsoOpenid::Urls.sso_openid.fqdn + "/",
        setup: true,
        scope: [:openid, :email, :profile, :address],
      }
    end
  end
end
