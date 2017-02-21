require "test_helper"
require "byebug"
class StatusTest < ActiveSupport::TestCase

  # Association Tests
  should have_many(:results)

  # Load Fixture
  fixture_status = Status.first

  # Instance Method Tests
  test "should set_defaults on new status" do
    status = Status.new
    status.set_defaults
    assert_equal(status.is_invalid, false)
    assert_equal(status.closed, false)
  end

  test "should reset_default on after_save callback" do
    assert_equal(fixture_status.reset_default.count, 2)
  end

  test "should to_string a name" do
    assert_equal(fixture_status.to_s, "Open")
  end
end
