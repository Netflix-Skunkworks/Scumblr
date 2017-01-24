require "test_helper"
require "byebug"
class CommentTest < ActiveSupport::TestCase

  # Validations Tests
  should validate_presence_of(:body)
  should validate_presence_of(:user)

  # Association Tests
  should belong_to(:commentable)
  should belong_to(:user)

  # Load Fixtured Event
  fixture_comment = Comment.first

  # Class Method Tests
  test "execute comment build_from function" do
    new_comment = Comment.build_from(Result.first, 1, "foo")
    new_comment.save!
    assert_equal(1, Result.first.comment_threads.count)
  end

  # Instance Method Tests
  test "execute has_children method" do
    assert_equal(false, fixture_comment.has_children?)
  end

  test "execute find_commentable method" do
    assert_equal(1, Comment.find_commentable("Result", 1).id)
  end
  # Helpter Method Tests
  # test "peform update_fields before save" do
  #   new_event = Event.new(action: "Error", field: "foo", new_value: "bar", old_value: "test")
  #   new_event.save!
  #   assert_instance_of(ActiveSupport::TimeWithZone, new_event.date)
  # end

  # test "peform private field_name call" do
  #   assert_equal("Task", fixture_event.send(:field_name))
  # end

  # # Instance Method Tests
  # test "should perform a single event search" do
  #   ransack, results = Event.perform_search(q={action_in: ["", "Error"], chronic_date_lteq: "today"}, 1, 25)
  #   assert_equal(results.length, 1)
  # end

  # test "should perform a single event greater search" do
  #   ransack, results = Event.perform_search(q={action_in: ["", "Error"], chronic_date_gteq: "November 10 2016"}, 1, 25)
  #   assert_equal(results.length, 1)
  # end

end
