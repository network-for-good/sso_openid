unless Rails.env.production?
  OpenIDConnect.http_config { |client| client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE }
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid_connect, NfgOpenid::Configuration.options

  on_failure { |env| NfgOpenid::AuthenticationsController.action(:failure).call(env) }
end
