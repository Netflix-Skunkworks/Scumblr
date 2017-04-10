require "test_helper"
require "byebug"
class SystemMetadataTest < ActiveSupport::TestCase

  # Validations Tests
  should validate_presence_of(:key)
  should validate_uniqueness_of(:key)
  should validate_presence_of(:metadata).with_message("bad json")

  # Association Tests

  #set_fixture_class system_metadata: SystemMetadata
  fixture_result = SystemMetadata.first

  # Instance Method Tests
  test "should dump raw metadata" do
    metadata = fixture_result.metadata_raw
    assert_equal(["foo", "bar", "usa"].to_s, metadata)
  end

  test "should change to JSON" do
    metadata = SystemMetadata.new(key: "test")
    raw = metadata.metadata_raw={"foo": "bar"}
    assert_equal({:foo=>"bar"}, raw)
  end

end
