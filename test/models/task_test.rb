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
  curl_task = Task.where(id: 54).first
  github_system_metadata_search = Task.where(id: 5).first
  bad_curl_task = Task.where(id: 55).first
  github_sync = Task.where(id: 56).first
  google_search = Task.where(id: 57).first
  # github_result = Result.last

  # Class Tests
  test "should return to_s" do
    assert_equal("Task 1", fixture_task.to_s)
  end

  test "should schedule task" do
    fixture_task.schedule_with_params("*", "1", "*", "*", "*")
    assert_equal("* 1 * * *", fixture_task.frequency)
  end

  test "should unschedule task" do
    fixture_task.unschedule
    assert_equal("", fixture_task.frequency)
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
    assert_nil(curl_task.perform_task)
  end

  test "should execute github sync task" do
    skip("Github OAuth Token not defined") if Rails.configuration.try(:github_oauth_token).blank?
    github_sync.perform_task
    res = Result.find(github_sync.metadata[:current_results]["updated"].first)

    assert_equal(1, github_sync.metadata[:current_results].count)

    # add assertion that langauges were analyzed
    assert_equal("Ruby", res.metadata["repository_data"]["primary_language"])

    # add assertion that langauges were analyzed
    assert(res.metadata["repository_data"]["languages"].keys.include? "Ruby")
  end
  test "should execute google search task" do
    skip("Google developer key not defined") if Rails.configuration.try(:google_developer_key).blank?
    google_search.perform_task

    assert_equal(1, google_search.metadata[:current_results].count)
  end

#  test "should execute system metadata search for github" do
#  	require 'byebug'
#  	byebug
#  	puts 1
#    github_system_metadata_search.perform_task
#    assert_equal("Failed", github_system_metadata_search.metadata["_last_status"])
#  end

  test "should execute badly configured curl task" do
    bad_curl_task.perform_task
    assert_equal("Failed", bad_curl_task.metadata["_last_status"])
  end
end
