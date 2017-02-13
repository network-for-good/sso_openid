module SsoOpenid
  module SpecHelpers
    def sso_openid_omniauth_stub_for(admin)
      OmniAuth.config.test_mode = true

      OmniAuth.config.mock_auth[:sso_openid] = OmniAuth::AuthHash.new({
        provider: 'sso-openid',
        uid: '379bbf97-d3d9-4206-97a8-c24421b6f4fa',
        info: {
          name: nil,
          email: admin.email,
          nickname: nil,
          first_name: "John",
          last_name: "Doe",
          gender: nil,
          image: nil,
          phone: nil,
          urls: nil
        },
        credentials: {
          id_token: 'asdf1234',
          token: 'qwer5678',
          refresh_token: nil,
          expires_in: 1800,
          scope: nil,
        },
        extra: {
          email: admin.email,
          email_verified: "true",
          family_name: "John",
          given_name: "Doe",
          preferred_username: admin.email,
          sub: "379bbf97-d3d9-4206-97a8-c24421b6f4fa" ,
          updated_at: 1462568750
        }
      })
    end
  end
end
