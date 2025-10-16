# Configure SsoOpenid
api_config = YAML.load_file(Rails.root.join('config', 'api-keys.yml'))
config_hash = api_config['defaults'].merge(api_config[Rails.env] || {})

SsoOpenid.configure do |config|
  config.identifier = config_hash['sso_openid']['client_id']
  config.secret = config_hash['sso_openid']['client_secret']
end

