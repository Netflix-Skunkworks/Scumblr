require "test_helper"
require "byebug"
class EventTest < ActiveSupport::TestCase

  # Validations Tests
  should validate_presence_of(:action)

  # Association Tests
  should belong_to(:user)
  should belong_to(:eventable)
  should have_many(:event_changes)

  # Attribute Tests
  should allow_value("foo").for(:field)
  should allow_value("new value").for(:new_value)
  should allow_value("old value").for(:old_value)

  Event.delete_all
  Rake::Task["db:fixtures:load"].execute

  # Load Fixtured Event
  fixture_event = Event.first

  # Callback Tests
  test "peform update_fields before save" do
    new_event = Event.new(action: "Error", field: "foo", new_value: "bar", old_value: "test")
    new_event.save!
    assert_instance_of(ActiveSupport::TimeWithZone, new_event.date)
  end

  test "peform private field_name call" do
    assert_equal("Task", fixture_event.send(:field_name))
  end

  # Instance Method Tests
  test "should perform a single event search" do
    ransack, results = Event.perform_search(q={action_in: ["", "Test"], chronic_date_lteq: "today"}, 1, 25)
    assert_equal(1, results.length)
  end

  test "should perform a single event greater search" do
    ransack, results = Event.perform_search(q={action_in: ["", "Test"], chronic_date_gteq: "November 10 2016"}, 1, 25)
    assert_equal(1, results.length)
  end

end
