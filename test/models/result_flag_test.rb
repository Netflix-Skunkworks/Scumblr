require "test_helper"
require "byebug"
class ResultFlagTest < ActiveSupport::TestCase

  # Association Tests
  should belong_to(:flag)
  should belong_to(:result)

  # Load Fixture
  fixture_result_flag = ResultFlag.first

  # Instance Method Tests
  test "should execute set_workflow" do
    fixture_result_flag.set_workflow
    assert_equal(1,fixture_result_flag.workflow_id)
  end
end
