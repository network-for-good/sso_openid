Rails.application.routes.draw do
  get "/admin/auth/:provider/callback" => "sso_openid/sessions#create", as: :callback
  get "/admin/auth/:provider/setup" => "sso_openid/sessions#setup", as: :setup
  get '/admin/sign_in' => redirect(SsoOpenid::Configuration.auth_path_with_provider), as: :new_admin_session
  get '/admin/sign_out' => 'sso_openid/sessions#destroy', as: :destroy_admin_session
end
