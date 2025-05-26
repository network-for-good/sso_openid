module SsoOpenid
  class SessionsController < ::ApplicationController
    include Rails.application.routes.url_helpers

    skip_before_action :authenticate_admin!, raise: false

    def create
      omniauth_data = request.env['omniauth.auth']
      admin = Admin.from_omniauth(omniauth_data, request.subdomain, request.ip)
      if admin.nil?
        failure
      else
        if admin.respond_to?(:restrict_access?) && admin.restrict_access?
          flash[:error] = "You don't have permission to access this site."
          failure
        elsif admin.respond_to?(:status) && admin.status != 'active'
          flash[:error] = "You cannot access this site. Your account has been disabled."
          failure
        else
          sso_openid_sign_in(admin)
          flash[:notice] = "You have logged in successfully."
          redirect_to sso_openid_after_sign_in_path, allow_other_host: true
        end
      end
    end

    def destroy
      sso_openid_sign_out
      redirect_to sso_openid_after_sign_out_path, allow_other_host: true
    end

    def failure
      redirect_to sso_openid_failure_path, allow_other_host: true
    end

    def setup
      # Set the redirect uri
      redirect_uri = sso_openid.callback_url(subdomain: request.subdomain, host: request.host, port: request.port)
      omniauth_strategy.options[:client_options][:redirect_uri] = redirect_uri
      Rails.logger.info "sso_openid: setting redirect_uri to #{redirect_uri}"

      # Set additional options if they're available as query strings
      omniauth_strategy.options[:login_hint] = params[:login_hint] if params[:login_hint].present?
      omniauth_strategy.options[:acr_values] = "activated:#{params[:activated]}" if params[:activated].present?
      omniauth_strategy.options[:acr_values] = "pwdReset:#{params[:pwdReset]}" if params[:pwdReset].present?

      # All finished!
      render plain: "Omniauth setup phase.", status: 200
    end

    private

    def omniauth_strategy
      @omniauth_strategy ||= request.env['omniauth.strategy']
    end

    def current_donor
      nil
    end
  end
end
