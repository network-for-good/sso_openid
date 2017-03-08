require "rails_helper"

describe SsoOpenid::Urls do
  it "should read the values of the urls.yml file and return a struct with the requested application urls" do
    expect(SsoOpenid::Urls.evo).to eq(OpenStruct.new(SsoOpenid::Urls[:evo]))
  end

  it "should return the host for a particular entry when asked" do
    expect(SsoOpenid::Urls.user_api_url_gp.host).to eq(SsoOpenid::Urls[:user_api_url_gp][:host])
  end

  it "should return the fqdm for a particular entry when asked" do
    expect(SsoOpenid::Urls.dms.fqdm).to eq(SsoOpenid::Urls[:dms][:fqdm])
  end

  context 'when operating in a different environment' do
    before do
      allow(Rails).to receive(:env).and_return("production")
      SsoOpenid::Urls.reset!
    end

    it "should return the server for that environment" do
      expect(SsoOpenid::Urls.evo.fqdm).to eq("https://sso.networkforgood.com")
    end
  end
end