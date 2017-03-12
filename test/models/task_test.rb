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
  curl_task = Task.last(4).first
  bad_curl_task = Task.last(3).first
  github_sync = Task.last(2).first
  google_search = Task.last
    # github_result = Result.last

  # Class Tests
  test "should return to_s" do
    assert_equal("Task 1", fixture_task.to_s)
  end

  test "should check task type is valid" do
    is_valid = Task.task_type_valid? "ScumblrTask::CurlAnalyzer"
    assert_equal(true, is_valid)
  end

  test "should create a tag list" do
    #fixture_task.tag_list=["Status"]
    assert_equal("Status", fixture_task.tag_list="Status")
  end

  test "should create a task type name" do
    #fixture_task.tag_list=["Status"]
    assert_equal("Github Repo Sync", fixture_task.task_type_name)
  end
  test "should create a task type options" do

    fixture_task.task_type_options
    refute_equal({}, fixture_task.task_type_options)
  end
  test "should set and get a subscriber_list" do
    fixture_task.subscriber_list="testscumblr@netflix.com"
    assert_equal("testscumblr@netflix.com", fixture_task.subscriber_list)
  end

  test "should execute simple curl task" do
    curl_task.perform_task
    assert_equal(nil, curl_task.perform_task)
  end

  test "should execute github sync task" do
    github_sync.perform_task
    assert_equal(1, github_sync.metadata[:current_results].count)
  end
  test "should execute google search task" do
    google_search.perform_task

    assert_equal(1, google_search.metadata[:current_results].count)
  end

  test "should execute badly configured curl task" do
    bad_curl_task.perform_task
    assert_equal("Failed", bad_curl_task.metadata["_last_status"])
  end
end
