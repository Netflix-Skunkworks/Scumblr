require "test_helper"

class SummaryTest < ActiveSupport::TestCase
  # Association Tests
  should belong_to(:summarizable)
end
