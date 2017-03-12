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
    assert_equal(false, status.is_invalid)
    assert_equal(false, status.closed)
  end

  test "should reset_default on after_save callback" do
    assert_equal(2, fixture_status.reset_default.count)
  end

  test "should to_string a name" do
    assert_equal("Open", fixture_status.to_s)
  end
end
