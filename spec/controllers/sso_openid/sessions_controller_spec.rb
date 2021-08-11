require 'rails_helper'

describe SsoOpenid::SessionsController, type: :controller do
  describe "#create" do
  end

  describe "#destroy" do
    before do
      @routes = SsoOpenid::Engine.routes
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
      application_redirect_path = "/my/applications/redirect/path"
      allow(controller).to receive(:sso_openid_after_sign_out_path).and_return(application_redirect_path)
      subject
      expect(response).to redirect_to(application_redirect_path)
    end
  end
end
