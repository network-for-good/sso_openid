Rails.application.routes.draw do
  mount SsoOpenid::Engine => "/"
  root to: 'application#root'
end
