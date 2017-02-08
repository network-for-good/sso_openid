module SsoOpenid
  module PathHelpers
    def sso_openid_auth_path_prefix
      "/admin/auth"
    end

    def sso_openid_provider_name
      "sso-openid"
    end

    def sso_openid_auth_path
      "#{sso_openid_auth_path_prefix}/#{sso_openid_provider_name}"
    end

    def sso_openid_callback_path
      "#{sso_openid_auth_path}/callback"
    end

    def sso_openid_setup_path
      "#{sso_openid_auth_path}/setup"
    end
  end
end
