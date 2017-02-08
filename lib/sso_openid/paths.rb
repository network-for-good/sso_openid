module SsoOpenid
  class Paths
    class << self
      def auth_path_prefix
        "/admin/auth"
      end

      def provider_name
        "sso-openid"
      end

      def auth_path
        "#{auth_path_prefix}/#{provider_name}"
      end

      def callback_path
        "#{auth_path}/callback"
      end

      def setup_path
        "#{auth_path}/setup"
      end
    end
  end
end
