require "rails_helper"

describe SsoOpenid::Urls do
  it "should read the values of the urls.yml file and return the requested application url " do
    expect(SsoOpenid::Urls.evo).to eq("https://sso-qa.givecorps.com")
  end

  it "using the hash signature with host should return the same value as the method signature" do
    expect(SsoOpenid::Urls.gp_users).to eq(SsoOpenid::Urls[:gp_users][:host])
  end

  context 'when operating in a different environment' do
    before do
      allow(Rails).to receive(:env).and_return("production")
      SsoOpenid::Urls.reset!
    end

    it "should return the server for that environment" do
      expect(SsoOpenid::Urls.evo).to eq("https://networkforgood.com")
    end
  end
end