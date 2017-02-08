module SsoOpenid
  class Middleware
    attr_accessor :app

    def initialize(app)
      self.app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      sso_openid_auth_path_prefix = '/admin/auth'
      if request.path =~ %r{#{sso_openid_auth_path_prefix}/?}
        omniauth_strategy = OmniAuth::Strategies::OpenIDConnect.new(app, SsoOpenid::Configuration.openid_options)
        status, headers, response = omniauth_strategy.call(env)
        return [status, headers, response]
      else
        status, headers, response = app.call(env)
        return [status, headers, response]
      end
    end
  end
end
