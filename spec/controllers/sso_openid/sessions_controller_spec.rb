require 'rails_helper'

describe SsoOpenid::SessionsController, type: :controller do
  before do
    @routes = SsoOpenid::Engine.routes
  end

  describe "#create" do
    let(:omniauth_data) { double('omniauth_data') }
    let(:admin) { double('Admin', uid: 'abc-123', id: 1) }
    let(:subdomain) { 'test' }
    let(:ip) { '127.0.0.1' }

    before do
      allow(request).to receive(:subdomain).and_return(subdomain)
      allow(request).to receive(:ip).and_return(ip)
      allow(request).to receive(:env).and_return({ 'omniauth.auth' => omniauth_data })
      allow(Admin).to receive(:from_omniauth).and_return(admin)
    end

    context "when admin is nil" do
      let(:admin) { nil }

      it "calls failure" do
        expect(controller).to receive(:failure)
        post :create
      end
    end

    context "when admin has restricted access" do
      before do
        allow(admin).to receive(:respond_to?).with(:restrict_access?).and_return(true)
        allow(admin).to receive(:restrict_access?).and_return(true)
        allow(controller).to receive(:sso_openid_failure_path).and_return('/failure')
      end

      it "sets an error flash message" do
        post :create
        expect(flash[:error]).to eq("You don't have permission to access this site.")
      end

      it "redirects to failure path" do
        post :create
        expect(response).to redirect_to('/failure')
      end
    end

    context "when admin is inactive" do
      before do
        allow(admin).to receive(:respond_to?).with(:restrict_access?).and_return(false)
        allow(admin).to receive(:respond_to?).with(:status).and_return(true)
        allow(admin).to receive(:status).and_return('inactive')
        allow(controller).to receive(:sso_openid_failure_path).and_return('/failure')
      end

      it "sets an error flash message" do
        post :create
        expect(flash[:error]).to eq("You cannot access this site. Your account has been disabled.")
      end

      it "redirects to failure path" do
        post :create
        expect(response).to redirect_to('/failure')
      end
    end

    context "when admin is valid" do
      let(:after_sign_in_path) { '/' }

      before do
        allow(admin).to receive(:respond_to?).with(:restrict_access?).and_return(false)
        allow(admin).to receive(:respond_to?).with(:status).and_return(true)
        allow(admin).to receive(:status).and_return('active')
        allow(controller).to receive(:sso_openid_sign_in)
        allow(controller).to receive(:sso_openid_after_sign_in_path).and_return(after_sign_in_path)
      end

      it "signs in the admin" do
        expect(controller).to receive(:sso_openid_sign_in).with(admin)
        # Stub redirect_to to avoid Rails 7.2 UnsafeRedirectError in tests
        allow(controller).to receive(:redirect_to)
        post :create
      end

      it "sets a success flash message" do
        # Stub redirect_to to avoid Rails 7.2 UnsafeRedirectError in tests
        allow(controller).to receive(:redirect_to)
        post :create
        expect(flash[:notice]).to eq("You have logged in successfully.")
      end

      it "redirects to after sign in path" do
        expect(controller).to receive(:redirect_to).with(after_sign_in_path)
        post :create
      end
    end
  end

  describe "#destroy" do
    before do
      session[:admin_uid] = 'abc-123'
      session[:admin_id] = 1
    end

    subject { get :destroy }

    it "removes the session uid" do
      subject
      expect(session[:admin_uid]).to be_nil
    end

    it "removes the session id" do
      subject
      expect(session[:admin_id]).to be_nil
    end

    it "redirects the user to whatever is returned from the sso_openid_after_sign_out_path method" do
      # the sso_openid_after_sign_out_path method must be defined in the application
      # controller of the containing application
      application_redirect_path = "https://unknown-host.example.com/my/applications/redirect/path"
      allow(controller).to receive(:sso_openid_after_sign_out_path).and_return(application_redirect_path)
      subject
      expect(response).to redirect_to(application_redirect_path)
    end
  end

  describe "#sso_openid_after_sign_out_path" do
    context "when host app defines the method" do
      it "calls super and uses host app's implementation" do
        allow(controller).to receive(:host_app_defines_method?).with(:sso_openid_after_sign_out_path).and_return(true)
        # The dummy app defines this method to return root_path
        expect(controller.send(:sso_openid_after_sign_out_path)).to eq(Dummy::Application.routes.url_helpers.root_path)
      end
    end

    context "when host app doesn't define the method" do
      before do
        allow(controller).to receive(:host_app_defines_method?).with(:sso_openid_after_sign_out_path).and_return(false)
        allow(SsoOpenid::Urls).to receive_message_chain(:sso_openid, :discovery_endpoint).and_return('https://auth.example.com')
        allow(SsoOpenid.configuration).to receive(:identifier).and_return('client-id-123')
        allow(controller).to receive(:sso_openid).and_return(double(auth_url: 'https://example.com/auth'))
        allow(controller).to receive(:request).and_return(double(host: 'example.com', port: 443, subdomain: 'www'))
      end

      it "returns the auth0 logout URL" do
        path = controller.send(:sso_openid_after_sign_out_path)
        expect(path).to include('https://auth.example.com/v2/logout')
        expect(path).to include('client_id=client-id-123')
        expect(path).to include('returnTo=')
      end
    end
  end

  describe "#sso_openid_failure_path" do
    context "when host app defines the method" do
      it "calls super and uses host app's implementation" do
        allow(controller).to receive(:host_app_defines_method?).with(:sso_openid_failure_path).and_return(true)
        # The dummy app defines this method to return root_path
        expect(controller.send(:sso_openid_failure_path)).to eq(Dummy::Application.routes.url_helpers.root_path)
      end
    end

    context "when host app doesn't define the method" do
      before do
        allow(controller).to receive(:host_app_defines_method?).with(:sso_openid_failure_path).and_return(false)
        allow(SsoOpenid::Urls).to receive_message_chain(:sso_openid, :discovery_endpoint).and_return('https://auth.example.com')
        allow(SsoOpenid.configuration).to receive(:identifier).and_return('client-id-123')
        allow(controller).to receive(:sso_openid).and_return(double(auth_url: 'https://example.com/auth'))
        allow(controller).to receive(:request).and_return(double(host: 'example.com', port: 443, subdomain: 'www'))
      end

      it "returns the auth0 logout URL" do
        path = controller.send(:sso_openid_failure_path)
        expect(path).to include('https://auth.example.com/v2/logout')
        expect(path).to include('client_id=client-id-123')
        expect(path).to include('returnTo=')
      end
    end
  end

  describe "#setup" do
    let(:omniauth_strategy) { double('omniauth_strategy', options: { client_options: {}, login_hint: nil, acr_values: nil }) }

    before do
      allow(controller).to receive(:omniauth_strategy).and_return(omniauth_strategy)
      allow(controller).to receive(:sso_openid).and_return(double(callback_url: 'https://example.com/callback'))
      allow(request).to receive(:subdomain).and_return('www')
      allow(request).to receive(:host).and_return('example.com')
      allow(request).to receive(:port).and_return(443)
      allow(Rails.logger).to receive(:info)
    end

    it "sets the redirect_uri in omniauth strategy options" do
      get :setup
      expect(omniauth_strategy.options[:client_options][:redirect_uri]).to eq('https://example.com/callback')
    end

    it "logs the redirect_uri" do
      expect(Rails.logger).to receive(:info).with("sso_openid: setting redirect_uri to https://example.com/callback")
      get :setup
    end

    it "returns status 200" do
      get :setup
      expect(response.status).to eq(200)
    end

    context "with login_hint parameter" do
      it "sets login_hint in omniauth strategy options" do
        get :setup, params: { login_hint: 'user@example.com' }
        expect(omniauth_strategy.options[:login_hint]).to eq('user@example.com')
      end
    end

    context "with activated parameter" do
      it "sets acr_values for activated in omniauth strategy options" do
        get :setup, params: { activated: 'true' }
        expect(omniauth_strategy.options[:acr_values]).to eq('activated:true')
      end
    end

    context "with pwdReset parameter" do
      it "sets acr_values for pwdReset in omniauth strategy options" do
        get :setup, params: { pwdReset: 'true' }
        expect(omniauth_strategy.options[:acr_values]).to eq('pwdReset:true')
      end
    end
  end

  describe "private methods" do
    let(:admin) { double('Admin') }

    describe "#admin_access_restricted?" do
      it "returns true when admin responds to restrict_access? and it returns true" do
        allow(admin).to receive(:respond_to?).with(:restrict_access?).and_return(true)
        allow(admin).to receive(:restrict_access?).and_return(true)
        expect(controller.send(:admin_access_restricted?, admin)).to be true
      end

      it "returns false when admin doesn't respond to restrict_access?" do
        allow(admin).to receive(:respond_to?).with(:restrict_access?).and_return(false)
        expect(controller.send(:admin_access_restricted?, admin)).to be false
      end

      it "returns false when admin responds to restrict_access? but it returns false" do
        allow(admin).to receive(:respond_to?).with(:restrict_access?).and_return(true)
        allow(admin).to receive(:restrict_access?).and_return(false)
        expect(controller.send(:admin_access_restricted?, admin)).to be false
      end
    end

    describe "#admin_inactive?" do
      it "returns true when admin responds to status and status is not 'active'" do
        allow(admin).to receive(:respond_to?).with(:status).and_return(true)
        allow(admin).to receive(:status).and_return('inactive')
        expect(controller.send(:admin_inactive?, admin)).to be true
      end

      it "returns false when admin doesn't respond to status" do
        allow(admin).to receive(:respond_to?).with(:status).and_return(false)
        expect(controller.send(:admin_inactive?, admin)).to be false
      end

      it "returns false when admin status is 'active'" do
        allow(admin).to receive(:respond_to?).with(:status).and_return(true)
        allow(admin).to receive(:status).and_return('active')
        expect(controller.send(:admin_inactive?, admin)).to be false
      end
    end

    describe "#host_app_defines_method?" do
      it "returns true when ApplicationController defines the method" do
        expect(controller.send(:host_app_defines_method?, :sso_openid_after_sign_out_path)).to be true
      end

      it "returns false when ApplicationController doesn't define the method" do
        expect(controller.send(:host_app_defines_method?, :nonexistent_method)).to be false
      end
    end

    describe "#request_params" do
      before do
        allow(request).to receive(:host).and_return('example.com')
        allow(request).to receive(:port).and_return(443)
        allow(request).to receive(:subdomain).and_return('www')
      end

      it "returns a hash with host, port, and subdomain" do
        expect(controller.send(:request_params)).to eq({
          host: 'example.com',
          port: 443,
          subdomain: 'www'
        })
      end
    end
  end
end
