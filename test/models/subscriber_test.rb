require "test_helper"
require "byebug"
class SubscriberTest < ActiveSupport::TestCase

  # Association Tests
  should belong_to(:subscribable)
  should belong_to(:user)

  # # Validations Tests
  should validate_uniqueness_of(:user_id).scoped_to([:subscribable_id, :subscribable_type, :email])

  # Load Fixture
  fixture_subscriber = Subscriber.first

  # Instance Method Tests
  test "should to_string a name" do
    assert_equal("testscumblr@netflix.com", fixture_subscriber.subscriber_email)
  end
end
