require "test_helper"
require "byebug"
class TaskResultTest < ActiveSupport::TestCase

  # Validations Tests
  should validate_uniqueness_of(:result_id).scoped_to(:task_id)

  # Association Tests
  should belong_to(:result)
  should belong_to(:task)
  should delegate_method(:task_type).to(:task)
  should delegate_method(:query).to(:task)

  fixture_task_result = TaskResult.first

  test "should return task name" do
    assert_equal("Google Search Test", fixture_task_result.task_name)
  end
end
