# Configure SsoOpenid
SsoOpenid.configure do |config|
  config.identifier = APP_CONFIG[:sso_openid][:client_id]
  config.secret = APP_CONFIG[:sso_openid][:client_secret]
end

