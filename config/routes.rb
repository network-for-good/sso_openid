NfgOpenid::Engine.routes.draw do
  get "auth/:provider/callback" => "authentications#create", as: :callback
  get "auth/:provider" => "authentications#new"
end
