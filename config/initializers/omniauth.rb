unless Rails.env.production?
  OpenIDConnect.http_config { |client| client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE }
end

Rails.application.config.middleware.use OmniAuth::Builder do
  on_failure do |env|
    request = Rack::Request.new(env)
    location = if request.path =~ %r{#{SsoOpenid::Paths.auth_path_prefix}/?}
                 SsoOpenid::Paths.auth_path
               else
                 env['omniauth.origin'] || '/'
               end
    Rack::Response.new(['302 Moved'], 302, 'Location' => location).finish
  end
end

Rails.application.config.middleware.use "SsoOpenid::Middleware"
