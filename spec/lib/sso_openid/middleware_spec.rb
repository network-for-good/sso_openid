require 'rails_helper'

describe SsoOpenid::Middleware, type: :request do
  # Stub the OpenID Connect discovery endpoint
  before(:each) do
    issuer = SsoOpenid::Urls.sso_openid.discovery_endpoint
    discovery_url = "#{issuer}/.well-known/openid-configuration"
    stub_request(:get, discovery_url)
      .to_return(
        status: 200,
        body: {
          issuer: issuer,
          authorization_endpoint: "#{issuer}/protocol/openid-connect/auth",
          token_endpoint: "#{issuer}/protocol/openid-connect/token",
          userinfo_endpoint: "#{issuer}/protocol/openid-connect/userinfo",
          jwks_uri: "#{issuer}/protocol/openid-connect/certs",
          end_session_endpoint: "#{issuer}/protocol/openid-connect/logout",
          response_types_supported: ["code", "id_token", "id_token token", "code id_token", "code token", "code id_token token"],
          subject_types_supported: ["public"],
          id_token_signing_alg_values_supported: ["RS256"]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
  describe "a regular request" do
    let(:response_text) { "root path" }
    before { get root_path }

    it "passes the request through to the application" do
      expect(response.body).to eql response_text
    end
  end

  describe "a request to the auth path" do
    before { get sso_openid.auth_path }

    let(:discovery_endpoint) { SsoOpenid::Urls.sso_openid.discovery_endpoint }
    let(:redirect_uri) { sso_openid.callback_url(subdomain: request.subdomain) }
    let(:encoded_redirect_uri) { ERB::Util.url_encode(redirect_uri) }
    let(:scope) { SsoOpenid::Configuration.openid_options[:scope] }
    let(:client_id) { SsoOpenid.configuration&.identifier }

    subject { response.location }

    it { should match(/#{discovery_endpoint}/) }
    it { should match(/redirect_uri=#{encoded_redirect_uri}/) }
    it { should match(/scope=#{scope}/) }
    it { should match(/client_id=#{client_id}/) }
    it { should match(/state=?/) }
    it { should match(/nonce=?/) }
  end

  describe "processing the callback" do
    let(:admin_email) { 'foo@bar.com' }
    let(:callback_path_with_args) { "/admin/auth/sso-openid/callback?code=031780c51f26288fdec53fdee74bcc78&state=543dbb070d9f0950bd4b3d7efeb35d16&session_state=ha2l7HaJjHevM_BPWIxIsX7cGC71a0-bt0RQuJ-2ZmU.4762d7ed83641f46d32a3499dbb929f6" }
    let(:omniauth_auth) do
      OmniAuth::AuthHash.new({
        provider: provider,
        uid: '379bbf97-d3d9-4206-97a8-c24421b6f4fa',
        credentials: {
          id_token: 'asdf1234',
          token: 'qwer5678',
          refresh_token: nil,
          expires_in: 1800,
          scope: nil,
        },
        extra: {
          email: admin_email,
          email_verified: "true",
          family_name: "John",
          given_name: "Doe",
          preferred_username: admin_email,
          sub: "379bbf97-d3d9-4206-97a8-c24421b6f4fa" ,
          updated_at: 1462568750
        }
      })
    end
    let(:admin) { Admin.new }
    let(:provider) { SsoOpenid::Paths.provider_name }

    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:sso_openid] = omniauth_auth
    end
    after { OmniAuth.config.test_mode = false }

    context "when an admin is found" do
      before do
        Rails.application.env_config["omniauth.auth"] = omniauth_auth
        allow(Admin).to receive(:from_omniauth) { admin }
      end

      it "signs in the admin" do
        expect_any_instance_of(SsoOpenid::SessionsController).to receive(:sso_openid_sign_in).with(admin)
        get callback_path_with_args
      end

      it "redirects the user" do
        get callback_path_with_args
        expect(response).to redirect_to(root_path)
      end

      it "creates a cookie" do
        get callback_path_with_args
        expect(cookies[:admin_uid]).to eql(omniauth_auth.credentials.uid)
      end
    end

    context "when an admin is not found" do
      before do
        Rails.application.env_config["omniauth.auth"] = omniauth_auth
        allow(Admin).to receive(:from_omniauth) { nil }
      end

      it "redirects to the failure path" do
        get callback_path_with_args
        expect(response).to redirect_to(root_path)
      end
    end
  end

end
