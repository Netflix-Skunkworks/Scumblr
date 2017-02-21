require "test_helper"
require "byebug"
class TaskTest < ActiveSupport::TestCase

  # Validations Tests
  should validate_presence_of(:name)
  should validate_uniqueness_of(:name)
  should validate_presence_of(:group)


  # Association Tests
  should have_many(:taggings).dependent(:delete_all)
  should have_many(:tags).through(:taggings)
  should have_many(:subscribers)
  should have_many(:task_results)
  should have_many(:results).through(:task_results)
  should have_many(:events)

  fixture_task = Task.first
  curl_task = Task.last(2).first
  bad_curl_task = Task.last
    # github_result = Result.last

  # Class Tests
  test "should return to_s" do
    assert_equal(fixture_task.to_s, "Task 1")
  end

  test "should check task type is valid" do
    is_valid = Task.task_type_valid? "ScumblrTask::CurlAnalyzer"
    assert_equal(is_valid, true)
  end

  test "should create a tag list" do
    #fixture_task.tag_list=["Status"]
    assert_equal(fixture_task.tag_list="Status", "Status")
  end

  test "should set and get a subscriber_list" do
    fixture_task.subscriber_list="testscumblr@netflix.com"
    assert_equal(fixture_task.subscriber_list, "testscumblr@netflix.com")
  end

  test "should execute simple curl task" do
    curl_task.perform_task
    assert_equal(curl_task.perform_task, nil)
  end

  test "should execute badly configured curl task" do
    bad_curl_task.perform_task
    assert_equal(bad_curl_task.metadata["_last_status"], "Failed")
  end
end
