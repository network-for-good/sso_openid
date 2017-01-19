class NfgOpenid::AuthenticationsController < ApplicationController
  def create
    omniauth_data = env['omniauth.auth']
    admin = Admin.from_omniauth(omniauth_data, request.subdomain)
    if admin
      sign_in(admin)
      redirect_to(admin_dashboard_path) and return
    else
      redirect_to(admin_access_not_allowed_path) and return
    end
  end

  def failure
    raise 'failure'
  end

  def setup
    request.env['omniauth.strategy'].options[:client_options][:redirect_uri] = callback_url('nfg-openid', subdomain: request.subdomain)
    render :text => "Omniauth setup phase.", :status => 200
  end

  private

  def current_donor
    nil
  end

  def state
    @state ||= SecureRandom.hex(32)
  end
end
