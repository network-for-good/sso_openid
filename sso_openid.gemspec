$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sso_openid/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sso_openid"
  s.version     = SsoOpenid::VERSION
  s.authors     = ["Timothy King"]
  s.email       = ["timothy.king@networkforgood.com"]
  s.homepage    = "http://github.com/NetworkForGood"
  s.summary = "OpenID implimentation for NFG Rails apps"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 5.0"
  s.add_dependency "omniauth", "~> 1.9.1"
  s.add_dependency "omniauth_openid_connect", "~> 0.3.0"
  s.add_dependency "json-jwt"
  s.add_dependency "nokogiri", ">= 1.11.4"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "rspec_junit_formatter"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "capybara"
end
