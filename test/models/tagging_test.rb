require "test_helper"
require "byebug"
class TaggingTest < ActiveSupport::TestCase

  # Association Tests
  should belong_to(:tag)
  should belong_to(:taggable)
  should validate_uniqueness_of(:tag_id).scoped_to([:taggable_id, :taggable_type])


end
