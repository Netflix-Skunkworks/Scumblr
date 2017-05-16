require "test_helper"
require "byebug"
class UserSavedFilterTest < ActiveSupport::TestCase
  # Association Tests
  should belong_to(:user)
  should have_many(:saved_filter)

end
