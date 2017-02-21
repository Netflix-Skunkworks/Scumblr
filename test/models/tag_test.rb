require "test_helper"
require "byebug"
class TagTest < ActiveSupport::TestCase
  # Association Tests
  should have_many(:taggings)
  should have_many(:taggables).through(:taggings).source(:taggable)

  # set_fixture_class system_metadata: SystemMetadata
  fixture_tag = Tag.first

  # Instance Method Tests
  test "should show tagged results" do
    # Should load up one tagged result
    tagged = fixture_tag.tagged("Result")
    assert_equal(tagged.count, 1)
  end

  test "should show name_value" do
    # Should load up one tagged result
    assert_equal(fixture_tag.name_value, "Foo: Bar")
  end

end
