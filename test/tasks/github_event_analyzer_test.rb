require "test_helper"
class GithubEventAnalyzerTest < ActiveSupport::TestCase
  # Class Method Tests
  test "execute callback on github_event and ensure it creates vulnerabilities" do
    task_params = Rails.root.join('test', 'data', 'github_event.json').read
    TaskRunner.new.perform(70, task_params)
    github_event_result = Result.where(id: 275235).first
    # Debugging
    puts github_event_result.metadata
    puts Task.where(id: 70).first
    puts File.open('/tmp/sidekiq.log').read
    assert_equal(1, github_event_result.metadata["vulnerabilities"].count)
  end
end
