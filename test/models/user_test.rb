require "test_helper"
require "byebug"
class UserTest < ActiveSupport::TestCase

  # Validations Tests
  should allow_value("test@netflix.com").for(:email)
  should_not allow_value("testnetflix.com").for(:email)

  # Association Tests
  should have_many(:saved_filters)
  should have_many(:user_saved_filters)
  should have_many(:added_saved_filters).through(:user_saved_filters).class_name("SavedFilter").source(:saved_filter)
  should have_many(:subscriptions).class_name("Subscriber")

end
