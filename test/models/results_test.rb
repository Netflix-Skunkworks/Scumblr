require "test_helper"

class ResultTest < ActiveSupport::TestCase

  test "get a result record" do
     result = Result.first
     assert_not_nil(result)
  end

end