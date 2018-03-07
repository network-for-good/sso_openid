require "rails_helper"

describe SsoOpenid::Urls do
  it "should read the values of the urls.yml file and return a struct with the requested application urls" do
    expect(SsoOpenid::Urls.evo).to eq(OpenStruct.new(SsoOpenid::Urls[:evo]))
  end

  it "should return the gp users_api for a particular entry when asked" do
    expect(SsoOpenid::Urls.gp.users_api).to eq(SsoOpenid::Urls[:gp][:users_api])
  end

  it "should return the evo host for a particular entry when asked" do
    expect(SsoOpenid::Urls.evo.host).to eq(SsoOpenid::Urls[:evo][:host])
  end


  it "should return the fqdm for a particular entry when asked" do
    expect(SsoOpenid::Urls.dms.fqdn).to eq(SsoOpenid::Urls[:dms][:fqdn])
  end


  it "should return the non-standard values for a particular entry when asked" do
    expect(SsoOpenid::Urls.sso_openid.discovery_endpoint).to eq(SsoOpenid::Urls[:sso_openid][:discovery_endpoint])
  end


  context 'when operating in a different environment' do
    before do
      allow(Rails).to receive(:env).and_return("production")
      SsoOpenid::Urls.reset!
    end

    it "should return the server for that environment" do
      expect(SsoOpenid::Urls.evo.fqdn).to eq("https://api.networkforgood.com")
    end
  end
end