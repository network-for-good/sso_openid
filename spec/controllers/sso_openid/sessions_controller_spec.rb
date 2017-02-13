require 'rails_helper'

describe SsoOpenid::SessionsController, type: :controller do
  describe "#create" do
  end

  describe "#destroy" do
    before do
      session[:admin_uid] = 'abc-123'
      session[:admin_id] = 1
      get :destroy, use_route: :sso_openid
    end

    it "removes the session uid" do
      expect(session[:admin_uid]).to be_nil
    end

    it "removes the session id" do
      expect(session[:admin_id]).to be_nil
    end

    it "redirects the user" do
      expect(response).to redirect_to('/')
    end

  end
end