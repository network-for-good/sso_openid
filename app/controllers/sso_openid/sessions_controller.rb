# frozen_string_literal: true

module SsoOpenid
  class SessionsController < ::ApplicationController
    include Rails.application.routes.url_helpers

    skip_before_action :authenticate_admin!, raise: false
    skip_before_action :verify_authenticity_token, only: %i[create setup], raise: false
    # (NFG-2884) Skip ensure_secondary_validation if it exists (only in donor_management app)
    # This allows the setup method to complete without being redirected for MFA
    skip_before_action :ensure_secondary_validation, only: [:setup], raise: false

    def create
      omniauth_data = request.env['omniauth.auth']
      return reauthentication_required unless auth_fresh?(omniauth_data)

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

      # Set connection parameter for Auth0 if configured
      if SsoOpenid.configuration&.connection_name.present?
        omniauth_strategy.options[:extra_authorize_params] ||= {}
        omniauth_strategy.options[:extra_authorize_params][:connection] = SsoOpenid.configuration&.connection_name
      end

      # (NFG-4485) Ask Auth0 to re-authenticate anyone whose last active login is older than
      # max_auth_age, instead of silently reusing its persistent session cookie. The strategy's
      # `max_age` option is not sent by omniauth_openid_connect 0.3.5, so it goes in as an
      # extra authorize param.
      if max_auth_age
        omniauth_strategy.options[:extra_authorize_params] ||= {}
        omniauth_strategy.options[:extra_authorize_params][:max_age] = max_auth_age
      end

      # All finished!
      render plain: 'Omniauth setup phase.', status: 200
    end

    private

    def max_auth_age
      SsoOpenid.configuration&.max_auth_age.presence&.to_i
    end

    # Auth0 only re-authenticates when asked, and does not enforce `max_age` on the way back,
    # so the callback has to check `auth_time` itself. Fails closed: a missing or unreadable
    # claim counts as stale.
    def auth_fresh?(omniauth_data)
      return true unless max_auth_age

      SsoOpenid::AuthFreshness.fresh?(omniauth_data&.credentials&.id_token, max_auth_age)
    end

    # Ends the Auth0 session and returns to the login screen, which forces a credential prompt.
    # Deliberately not `failure`: host apps point that at an error page.
    def reauthentication_required
      Rails.logger.info 'sso_openid: auth_time older than max_auth_age, forcing re-authentication'
      redirect_to auth0_logout_url, allow_other_host: true
    end

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

    # old discovery_endpoint values logic as below
    # SsoOpenid::Urls.sso_openid.discovery_endpoint
    def auth0_logout_url
      # Auth0 logout endpoint with returnTo parameter to redirect back to the login screen
      login_url = sso_openid.auth_url(**request_params)
      "#{SsoOpenid.configuration&.discovery_endpoint}/v2/logout?client_id=#{SsoOpenid.configuration.identifier}&returnTo=#{CGI.escape(login_url)}"
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
