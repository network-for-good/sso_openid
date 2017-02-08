module SsoOpenid
  class Engine < ::Rails::Engine
    config.to_prepare do
      ::ApplicationController.helper(SsoOpenid::PathHelpers)
      #::ApplicationController.helper(SsoOpenid::ApplicationHelper)
    end
  end
end
