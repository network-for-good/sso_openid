require "nfg_openid/engine"
require "omniauth/openid_connect"

module NfgOpenid
  class Configuration
    def self.options
      {
        client_options: {
          port: 443,
          scheme: "https",
          host: APP_CONFIG[:nfg_openid][:host],
          identifier: APP_CONFIG[:nfg_openid][:client_id],
          secret: APP_CONFIG[:nfg_openid][:client_secret],
        },
        callback_path: "/admin/auth/nfg-openid/callback",
        name: 'nfg-openid',
        discovery: true,
        issuer: APP_CONFIG[:nfg_openid][:discovery_endpoint],
        state: Proc.new { SecureRandom.hex(32) }
      }
    end
  end
end
