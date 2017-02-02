Rails.application.routes.draw do
  get "/admin/auth/:provider/callback" => "sso_openid/authentications#create", as: :callback
  get "/admin/auth/:provider/setup" => "sso_openid/authentications#setup", as: :setup
end
