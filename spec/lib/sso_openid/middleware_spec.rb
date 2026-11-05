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

  # NFG-3714: omniauth 2 only runs the request phase on POST (its fix for CVE-2015-9284). These
  # drive the real OpenIDConnect strategy, with only Auth0's discovery document stubbed.
  describe "the request phase" do
    let(:auth_path) { SsoOpenid::Paths.auth_path }
    let(:issuer) { "https://auth.example.com/" }
    let(:client_id) { "test-client-id" }
    let(:discovery_url) { "https://auth.example.com/.well-known/openid-configuration" }
    let(:scope) { SsoOpenid::Configuration.openid_options[:scope] }

    around do |example|
      previous = SsoOpenid.configuration
      SsoOpenid.configuration = SsoOpenid::Configuration.new
      SsoOpenid.configure do |config|
        config.identifier = client_id
        config.secret = "test-secret"
        config.host = "auth.example.com"
        config.discovery_endpoint = "https://auth.example.com"
      end
      example.run
    ensure
      SsoOpenid.configuration = previous
    end

    before do
      stub_request(:get, discovery_url).to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          issuer: issuer,
          authorization_endpoint: "https://auth.example.com/authorize",
          token_endpoint: "https://auth.example.com/oauth/token",
          userinfo_endpoint: "https://auth.example.com/userinfo",
          jwks_uri: "https://auth.example.com/.well-known/jwks.json",
          response_types_supported: ["code"],
          subject_types_supported: ["public"],
          id_token_signing_alg_values_supported: ["RS256"]
        }.to_json
      )
    end

    describe "GET (how every host app starts a login)" do
      it "renders a self-submitting form that POSTs back to the auth path instead of redirecting" do
        get auth_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(%(id="sso-openid-request-form"))
        expect(response.body).to include(%(action="#{auth_path}"))
        expect(response.body).to include(%(method="post"))
        expect(a_request(:get, discovery_url)).not_to have_been_made
      end

      it "keeps the query string on the form action" do
        get "#{auth_path}?login_hint=user%40example.com"

        expect(response.body).to include(%(action="#{auth_path}?login_hint=user%40example.com"))
      end
    end

    describe "POST" do
      subject(:location) { response.location }

      before { post auth_path }

      it "redirects to the identity provider's authorization endpoint" do
        expect(response).to have_http_status(:found)
        expect(location).to start_with("https://auth.example.com/authorize?")
      end

      it { should include("client_id=#{client_id}") }
      it { should include("response_type=code") }
      it { should match(/scope=#{scope.join('(\\+|%20)')}/) }
      it { should match(/state=\h+/) }
      it { should match(/nonce=\h+/) }

      it "sends the callback URL that the setup phase computed from the request host" do
        expect(CGI.unescape(location)).to include("redirect_uri=http://www.example.com#{SsoOpenid::Paths.callback_path}")
      end

      context "with login_hint in the query string" do
        before { post "#{auth_path}?login_hint=user%40example.com" }

        it { should include("login_hint=user%40example.com") }
      end
    end

    describe "POST with forgery protection on, as in production" do
      around do |example|
        ActionController::Base.allow_forgery_protection = true
        example.run
      ensure
        ActionController::Base.allow_forgery_protection = false
      end

      it "rejects a POST that carries no authenticity token (the CVE-2015-9284 case)" do
        post auth_path

        expect(response).to have_http_status(:found)
        expect(response.location).to include("/auth/failure?message=")
        expect(response.location).not_to include("auth.example.com/authorize")
        expect(a_request(:get, discovery_url)).not_to have_been_made
      end

      it "accepts the token minted by the GET page" do
        get auth_path
        token = response.body[/name="authenticity_token" value="([^"]+)"/, 1]
        expect(token).to be_present

        post auth_path, params: { authenticity_token: token }

        expect(response).to have_http_status(:found)
        expect(response.location).to start_with("https://auth.example.com/authorize?")
      end
    end
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
