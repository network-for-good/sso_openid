module SsoOpenid
  class Engine < ::Rails::Engine
    isolate_namespace SsoOpenid

    initializer "sso_openid_mount_engine", before: :load_config_initializers do |app|
      Rails.application.routes.prepend do
        mount SsoOpenid::Engine, at: "/"
      end
    end

    initializer "sso_openid.action_controller" do |app|
      app.reloader.to_prepare do
        ActiveSupport.on_load :action_controller do
          include SsoOpenid::ApplicationHelper
          helper SsoOpenid::ApplicationHelper
        end
      end
    end
  end
end
