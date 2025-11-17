# frozen_string_literal: true

module SsoOpenid
  class SessionsController < ::ApplicationController
    include Rails.application.routes.url_helpers

    skip_before_action :authenticate_admin!, raise: false
    skip_before_action :verify_authenticity_token, only: %i[create setup], raise: false

    def create
      omniauth_data = request.env['omniauth.auth']
      admin = Admin.from_omniauth(omniauth_data, request.subdomain, request.ip)

      return failure if admin.nil?
      return handle_restricted_access(admin) if admin_access_restricted?(admin)
      return handle_inactive_admin(admin) if admin_inactive?(admin)

      sign_in_admin(admin)
    end

    def destroy
      sso_openid_sign_out
      redirect_to sso_openid_after_sign_out_path, allow_other_host: true
    end

    def sso_openid_after_sign_out_path
      return super if host_app_defines_method?(:sso_openid_after_sign_out_path)

      auth0_logout_url
    end

    def failure
      redirect_to sso_openid_failure_path, allow_other_host: true
    end

    def sso_openid_failure_path
      return super if host_app_defines_method?(:sso_openid_failure_path)

      auth0_logout_url
    end

    def setup
      # Set the redirect uri
      redirect_uri = sso_openid.callback_url(**request_params)
      omniauth_strategy.options[:client_options][:redirect_uri] = redirect_uri
      Rails.logger.info "sso_openid: setting redirect_uri to #{redirect_uri}"

      # Set additional options if they're available as query strings
      omniauth_strategy.options[:login_hint] = params[:login_hint] if params[:login_hint].present?
      omniauth_strategy.options[:acr_values] = "activated:#{params[:activated]}" if params[:activated].present?
      omniauth_strategy.options[:acr_values] = "pwdReset:#{params[:pwdReset]}" if params[:pwdReset].present?

      # All finished!
      render plain: 'Omniauth setup phase.', status: 200
    end

    private

    def admin_access_restricted?(admin)
      admin.respond_to?(:restrict_access?) && admin.restrict_access?
    end

    def admin_inactive?(admin)
      admin.respond_to?(:status) && admin.status != 'active'
    end

    def handle_restricted_access(_admin)
      flash[:error] = "You don't have permission to access this site."
      failure
    end

    def handle_inactive_admin(_admin)
      flash[:error] = 'You cannot access this site. Your account has been disabled.'
      failure
    end

    def sign_in_admin(admin)
      sso_openid_sign_in(admin)
      flash[:notice] = 'You have logged in successfully.'
      redirect_to sso_openid_after_sign_in_path
    end

    def host_app_defines_method?(method_name)
      ::ApplicationController.instance_methods(false).include?(method_name)
    end

    def auth0_logout_url
      # Auth0 logout endpoint with returnTo parameter to redirect back to the login screen
      login_url = sso_openid.auth_url(**request_params)
      "#{SsoOpenid::Urls.sso_openid.discovery_endpoint}/v2/logout?client_id=#{SsoOpenid.configuration.identifier}&returnTo=#{CGI.escape(login_url)}"
    end

    def request_params
      { host: request.host, port: request.port, subdomain: request.subdomain }
    end

    def omniauth_strategy
      @omniauth_strategy ||= request.env['omniauth.strategy']
    end

    def current_donor
      nil
    end
  end
end
