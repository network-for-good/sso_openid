require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require 'rspec/rails'
Rails.backtrace_cleaner.remove_silencers!

#
# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.include SsoOpenid::PathHelpers
  config.order = "random"

 #config.include SeleniumHelper, :type => :feature

 config.before(:suite) do
   DatabaseCleaner.strategy = :truncation
 end

 config.before(:each, js: true) do
   DatabaseCleaner.start
 end

 config.after(:each, js: true) do
   DatabaseCleaner.clean
 end
end

#Capybara.register_driver :selenium do |app|
  #Capybara::Selenium::Driver.new(app, :browser => :chrome)
#end