require 'rails_helper'

def redirect_to(path)
  true
end

describe SsoOpenid::ApplicationHelper do
  let(:admin) { Admin.new }
  let(:options) { {} }

  describe '#sso_openid_sign_in' do

    context "storing the admin" do
      before { sso_openid_sign_in(admin, options) }

      let(:options) { {} }

      it "stores the admin_uid" do
        expect(session[:admin_uid]).to eql(admin.uid)
      end

      it "stores the admin_id" do
        expect(session[:admin_id]).to eql(admin.id)
      end

      it "sets the current_admin" do
        expect(@current_admin).to eql(admin)
      end
    end

    context "not storing the admin" do
      before { sso_openid_sign_in(admin, options) }

      let(:options) { { store: false } }

      it "does not store the admin_uid" do
        expect(session[:admin_uid]).to be_nil
      end

      it "does not store the admin_id" do
        expect(session[:admin_id]).to be_nil
      end

      it "sets the current_admin" do
        expect(@current_admin).to eql(admin)
      end
    end

    it 'will run the after sign in call backs' do
      expect(self).to receive(:after_sso_sign_in_call_back)
      sso_openid_sign_in(admin, options)
    end
  end

  describe "#sso_openid_sign_out" do
    subject { sso_openid_sign_out }

    before do
      allow(self).to receive(:reset_session)
      session[:admin_uid] = 'abc-123'
      session[:admin_id] = 1
    end

    it "deletes the admin_uid from the session" do
      subject
      expect(session[:admin_uid]).to be_nil
    end

    it "deletes the admin_id from the session" do
      subject
      expect(session[:admin_id]).to be_nil
    end

    it "resets the session" do
      expect(self).to receive(:reset_session)
      subject
    end
  end

  describe "#authenticate_admin!" do
    subject { authenticate_admin! }

    context "when a current_admin is present" do
      before { @current_admin = admin }

      it { should be_truthy }
    end

    context "with no current_admin" do
      let(:path) { '/foo' }
      let(:request) { double("Request", fullpath: path) }

      it "sets the stored_location" do
        subject
        expect(session[:stored_location]).to eql path
      end

      it "redirects to the provider path" do
        expect(self).to receive(:redirect_to).with(sso_openid.auth_path)
        subject
      end

      context "with additional params" do
        let!(:params) { { login_hint: 'foo@bar.com' } }
        it "does not include additional params when redirecting" do
          expect(self).to receive(:redirect_to).with(sso_openid.auth_path)
          subject
        end
      end
    end
  end

  describe "#stored_location" do
    let(:path) { '/bar' }

    before { session[:stored_location] = path }
    subject { stored_location }

    it { should eql path }

    it "removes the stored_location from the session" do
      expect(session).to receive(:delete).with(:stored_location)
      subject
    end
  end
end
