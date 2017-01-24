require "test_helper"
require "byebug"
class SavedFilterTest < ActiveSupport::TestCase

  # Association Tests
  should have_many(:user_saved_filters).dependent(:delete_all)
  should have_many(:users).through(:user_saved_filters)
  should have_many(:subscribers)
  should have_many (:summaries)

  # Validation Tests
  should validate_presence_of(:name)
  should allow_value("Event").for(:saved_filter_type)
  should allow_value("Result").for(:saved_filter_type)
  should_not allow_value("Blah").for(:saved_filter_type).with_message("Blah is not a valid filter type")

  # ActiveRecord Matcher Tests
  should serialize(:query)

  # # Load Fixture
  # fixture_result_flag = ResultFlag.first

  # # Instance Method Tests
  # test "should execute set_workflow" do
  #   fixture_result_flag.set_workflow
  #   assert_equal(fixture_result_flag.workflow_id, 1)
  # end
end
