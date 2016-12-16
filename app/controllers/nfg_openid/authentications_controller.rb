class NfgOpenid::AuthenticationsController < ApplicationController
  def create
    raise env['omniauth.auth'].inspect
  end

  def new
    # The redirect_uri option has to be set here because it changes based on the subdomain
    provider.options[:client_options][:redirect_uri] = callback_url('nfg-openid', subdomain: request.subdomain)
    redirect_to provider.request_phase.last["Location"]
  end

  def failure
  end

  private

  def current_donor
    nil
  end

  def provider
    @provider ||= OmniAuth::Strategies::OpenIDConnect.new(Rails.application, NfgOpenid::Configuration.options)
  end
end
