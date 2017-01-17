#NfgOpenid::Engine.routes.draw do
Rails.application.routes.draw do
  get "/admin/auth/:provider/callback" => "nfg_openid/authentications#create", as: :callback
  get "/admin/auth/:provider/setup" => "nfg_openid/authentications#setup", as: :setup
end
