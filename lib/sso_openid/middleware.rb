module SsoOpenid
  class Middleware
    attr_accessor :app

    def initialize(app)
      self.app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      sso_openid_auth_path_prefix = SsoOpenid::Paths.auth_path_prefix

      Rails.logger.info "Middleware: Request path:  #{request.path}"

      if request.path =~ %r{#{sso_openid_auth_path_prefix}/?}
        omniauth_strategy = OmniAuth::Strategies::OpenIDConnect.new(app, SsoOpenid::Configuration.openid_options)
        begin
          status, headers, response = omniauth_strategy.call(env)
          return [status, headers, response]
        rescue Rack::OAuth2::Client::Error => e
          Rails.logger.info "Caught invalid grant error. #{e.inspect}"
          return [302, {'Location' => SsoOpenid::Paths.auth_path, 'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
        end
      else
        status, headers, response = app.call(env)
        return [status, headers, response]
      end
    end
  end
end
