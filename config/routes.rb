SsoOpenid::Engine.routes.draw do
  get SsoOpenid::Paths.callback_path => "sessions#create", as: :callback
  get SsoOpenid::Paths.setup_path => "sessions#setup", as: :setup
  get SsoOpenid::Paths.auth_path => "sessions#new", as: :auth
  get SsoOpenid::Paths.failure_path => "sessions#failure", as: :failure
  get '/admin/sign_out' => 'sessions#destroy', as: :destroy_admin_session
end
