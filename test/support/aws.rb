require "test_helper"
require "byebug"
require "aws-sdk"
class AwsTest < ActiveSupport::TestCase

  # S3 SDK Tests
  test "can conect and list S3" do
    if ENV['AWS_ACCESS_KEY_ID'].present?
      s3 = Aws::S3::Client.new(region: "us-east-1")
      assert_equal(true, s3.list_buckets.successful?)
    else
      skip("Not deployed on AWS, skipping...")
    end
  end
end
