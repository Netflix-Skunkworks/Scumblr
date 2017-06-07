require "test_helper"
require "byebug"
class EventChangeTest < ActiveSupport::TestCase
  # Association Tests
  should belong_to(:event)
end
