Rails.application.routes.draw do
  root to: 'application#root'
	get '/' => 'application#root', as: :default
end
