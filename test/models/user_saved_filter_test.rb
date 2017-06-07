require "test_helper"
require "byebug"
class UserSavedFilterTest < ActiveSupport::TestCase
  # Association Tests
  should belong_to(:user)
  should belong_to(:saved_filter)

end
