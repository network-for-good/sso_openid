module SsoOpenid
  class AuthenticationsController < ::ApplicationController

    def create
      omniauth_data = env['omniauth.auth']
      admin = Admin.from_omniauth(omniauth_data, request.subdomain)
      if admin
        admin.uid = omniauth_data.uid
        admin.oauth_token = omniauth_data.credentials.token
        admin.oauth_expires_at = DateTime.now + omniauth_data.credentials.expires_in.seconds
        sso_openid_sign_in_and_redirect(admin, omniauth_data)
      else
        failure
      end
    end

    def failure
      redirect_to sso_openid_failure_path
    end

    def setup
      request.env['omniauth.strategy'].options[:client_options][:redirect_uri] = callback_url('sso-openid', subdomain: request.subdomain)
      render :text => "Omniauth setup phase.", :status => 200
    end

    private

    def current_donor
      nil
    end
  end
end
