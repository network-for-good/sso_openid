class NfgOpenid::AuthenticationsController < ApplicationController
  def create
    raise env['omniauth.auth'].inspect
  end

  def new
    # We have to manually set the omniauth.state value to ensure we can match it in the callback phase
    session['omniauth.state'] = state

    # The redirect_uri option has to be set here because it changes based on the subdomain
    provider.options[:client_options][:redirect_uri] = callback_url('nfg-openid', subdomain: request.subdomain)

    # Finally, we redirect to the provider
    redirect_to provider.request_phase.last["Location"]
  end

  def failure
  end

  private

  def current_donor
    nil
  end

  def state
    @state ||= SecureRandom.hex(32)
  end

  def provider
    @provider ||= OmniAuth::Strategies::OpenIDConnect.new(Rails.application, NfgOpenid::Configuration.options.merge(state: Proc.new { p(state) }))
  end
end
