SsoOpenid::Engine.routes.draw do
  get SsoOpenid::Paths.callback_path => "sso_openid/sessions#create", as: :sso_openid_callback
  get SsoOpenid::Paths.setup_path => "sso_openid/sessions#setup", as: :sso_openid_setup
  get SsoOpenid::Paths.auth_path => "sso_openid/sessions#new", as: :sso_openid_auth
  get '/admin/sign_out' => 'sso_openid/sessions#destroy', as: :destroy_admin_session
end
