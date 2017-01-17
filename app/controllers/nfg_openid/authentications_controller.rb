class NfgOpenid::AuthenticationsController < ApplicationController
  def create
    raise session['omniauth.auth'].inspect
  end

  def failure
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
