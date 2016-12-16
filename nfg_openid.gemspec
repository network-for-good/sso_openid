$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "nfg_openid/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "nfg_openid"
  s.version     = NfgOpenid::VERSION
  s.authors     = ["Timothy King"]
  s.email       = ["timothy.king@networkforgood.com"]
  s.homepage    = "http://github.com/NetworkForGood"
  s.summary = "OpenID implimentation for NFG Rails apps"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.0"
  s.add_dependency "omniauth", "~> 1.3.0"
  s.add_dependency "omniauth-openid-connect"

  s.add_development_dependency "sqlite3"
end
