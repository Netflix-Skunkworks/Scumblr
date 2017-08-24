require 'simplecov'


# SimpleCov.start :rails do
#   add_group "Custom", "#{SimpleCov.root + '/../custom/'}"
# end

SimpleCov.profiles.define 'scumblr' do
  load_profile 'rails'
  filters.clear
  add_filter do |src|
    root_filter ||= /\A#{Regexp.escape(SimpleCov.root)}/io
    !(src.filename =~ root_filter)
  end
  add_filter "/test/"
  add_filter "/features/"
  add_filter "/spec/"
  add_filter "/autotest/"
  add_filter "/.rvm/"
  add_filter "/vendor/bundle/"
  add_filter "/config/"
  add_filter "/db/"

  add_group "Controllers", "app/controllers"
  add_group "Channels", "app/channels" if defined?(ActionCable)
  add_group "Models", "app/models"
  add_group "Mailers", "app/mailers"
  add_group "Helpers", "app/helpers"
  add_group "Jobs", %w(app/jobs app/workers)
  add_group "Libraries", "lib"
  add_group "Custom-Controllers", "../custom/app/controllers"
  add_group "Custom-Helpers", "../custom/app/helpers"
  add_group "Custom-Lib", "../custom/lib"
  track_files "{.,../custom}/{app,lib}/**/*.rb"

  #track_files "#{SimpleCov.root + '/../custom/'}{app,lib}/**/*.rb"
end
SimpleCov.start :scumblr

ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |rb| require(rb) }
require "rails/test_help"
require "minitest/rails"
require "paperclip/matchers"
require "minitest/reporters"

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new, Minitest::Reporters::JUnitReporter.new]
#require 'database_cleaner'
#DatabaseCleaner.strategy = :truncation#, {:pre_count => true}
#DatabaseCleaner.clean_with(:truncation)
#

# class Minitest::Rails::ActionController::TestCase
#   def setup
#     require 'byebug'
#     byebug
#     puts 1
#     DatabaseCleaner.start
#   end

#   def teardown
#     DatabaseCleaner.clean
#   end
# end
# To add Capybara feature tests add `gem "minitest-rails-capybara"`
# to the test group in the Gemfile and uncomment the following:
# require "minitest/rails/capybara"

# Uncomment for awesome colorful output
# require "minitest/pride"

class ActiveSupport::TestCase
  extend Paperclip::Shoulda::Matchers
  self.use_transactional_fixtures = true
  fixtures :all
  # Add more helper methods to be used by all tests here...
  # def setup
  # 	Rake::Task["db:fixtures:load"].execute
  #   DatabaseCleaner.start

  # end

  # def teardown
  #   DatabaseCleaner.clean

  # end
end

# Shoulda::Matchers.configure do |config|
#   config.integrate do |with|
#     # Choose a test framework:
#     with.test_framework :minitest
#     with.library :rails
#   end
# end

#does sign in for integration tests
module SignInHelper
  def sign_in
    host! 'localhost:3000'
    post_via_redirect user_session_path, {"user[email]" => 'testscumblr@netflix.com', "user[password]" => Rails.application.config.test_password, commit: "Sign in"}
    assert_response :success
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
