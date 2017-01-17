unless Rails.env.production?
  OpenIDConnect.http_config { |client| client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE }
end

Rails.application.config.middleware.use "NfgOpenid::Middleware"
