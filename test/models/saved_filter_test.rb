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
  fixture_saved_filter = SavedFilter.first

  # Instance Method Tests
  test "should return a subscriber_list" do
    emails = fixture_saved_filter.subscriber_list
    assert_equal("testscumblr@netflix.com", emails)
  end

  test "should set a subscriber_list" do
    fixture_saved_filter.subscriber_list="testscumblr@netflix.com"
    assert_equal("testscumblr@netflix.com", fixture_saved_filter.subscriber_list)
  end

  test "should perform_search" do
    ransack, results = fixture_saved_filter.perform_search()
    assert_equal(1, results.length)
  end
end
