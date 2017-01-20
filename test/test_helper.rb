require 'simplecov'
SimpleCov.start
ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |rb| require(rb) }
require "rails/test_help"
require "minitest/rails"
require "paperclip/matchers"

# To add Capybara feature tests add `gem "minitest-rails-capybara"`
# to the test group in the Gemfile and uncomment the following:
# require "minitest/rails/capybara"

# Uncomment for awesome colorful output
# require "minitest/pride"

class ActiveSupport::TestCase
  extend Paperclip::Shoulda::Matchers
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  # Add more helper methods to be used by all tests here...

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
