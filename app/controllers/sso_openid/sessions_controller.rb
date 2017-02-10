module SsoOpenid
  class SessionsController < ::ApplicationController

    def create
      omniauth_data = env['omniauth.auth']
      admin = Admin.from_omniauth(omniauth_data, request.subdomain, request.ip)
      if admin.nil?
        failure
      else
        if admin.respond_to?(:restrict_access?) && admin.restrict_access?
          flash[:error] = "You don't have permission to access this site"
          failure
        elsif admin.respond_to?(:status) && admin.status != 'active'
          flash[:error] = "You cannot access this site. Your account has been disabled."
          failure
        else
          sso_openid_sign_in(admin)
          flash[:notice] = "Signed in successfully"
          redirect_to sso_openid_redirect_after_sign_in_path
        end
      end
    end

    def destroy
      sso_openid_sign_out
      redirect_to root_path
    end

    def failure
      redirect_to sso_openid_failure_path
    end

    def setup
      redirect_uri = sso_openid_callback_url(subdomain: request.subdomain, host: request.host, port: request.port)
      request.env['omniauth.strategy'].options[:client_options][:redirect_uri] = redirect_uri
      Rails.logger.info "sso_openid: setting redirect_uri to #{redirect_uri}"
      render :text => "Omniauth setup phase.", :status => 200
    end

    private

    def current_donor
      nil
    end
  end
end
