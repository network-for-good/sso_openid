module NfgOpenid
  class Middleware
    attr_accessor :app

    def initialize(app)
      self.app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      if request.path =~ %r{#{NfgOpenid::Configuration.auth_path}/?}
        omniauth_strategy = OmniAuth::Strategies::OpenIDConnect.new(app, NfgOpenid::Configuration.openid_options)
        status, headers, response = omniauth_strategy.call(env)
        return [status, headers, response]
      else
        status, headers, response = app.call(env)
        return [status, headers, response]
      end
    end
  end
end
