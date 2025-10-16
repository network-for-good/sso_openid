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
      
      # Temporary hardcoded Auth0 credentials for UAT/beta environment
      # TODO: Remove this once api-keys.yml is updated by DevOps team
      client_id = sso_config[:client_id]
      client_secret = sso_config[:client_secret]
      
      # Fallback to hardcoded Auth0 credentials if old Identity Server credentials detected
      if client_id == 'N4GW3BAuc' || client_id == '1234' || Rails.env.beta?
        client_id = 'MEWrh8cWedRRMFsyJQZ6HOEfuuiH8ikB'
        client_secret = 'ZzdKZ7uctbp1ABbDHk3d8D1zTgmB-03YWVIhcQUwFtQgFOYV9u-8UXpt7odHvtXZ'
      end
      
      {
        client_options: {
          port: 443,
          scheme: "https",
          host: SsoOpenid::Urls.sso_openid.host,
          identifier: client_id,
          secret: client_secret,
        },
        callback_path: SsoOpenid::Paths.callback_path,
        request_path: SsoOpenid::Paths.auth_path,
        setup_path: SsoOpenid::Paths.setup_path,
        name: :sso_openid,
        discovery: true,
        issuer: SsoOpenid::Urls.sso_openid.discovery_endpoint,
        setup: true,
        scope: [:openid, :email, :profile, :address],
      }
    end
  end
end
