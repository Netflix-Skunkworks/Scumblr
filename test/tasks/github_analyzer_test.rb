require "test_helper"
require "byebug"
class GithubAnalyzerTest < ActiveSupport::TestCase
  # Load Fixtured Event
  github_search_fixture = Task.where(id: 58).first
  github_repo_fixture = Task.where(id: 59).first
  github_term_metadata = SystemMetadata.where(id: 2).first
  github_org_metadata = SystemMetadata.where(id: 3).first

  # Class Method Tests
  test "execute saved github search task with public members" do
    # This should help with some github stuff
    # and also did it create vulns correctly.

    github_search_fixture.perform_task
    github_repo_fixture.perform_task
    byebug

    # Return 2 results from test github org
    assert_equal(2, github_search_fixture.metadata[:current_results].count)
    # Check that 2 results were created with right # of vulns
    assert_equal(2, Result.where(id: 3).first.metadata["vulnerabilities"].count)
    assert_equal(2, Result.where(id: 4).first.metadata["vulnerabilities"].count)
    # check key_suffix is correct
    assert_equal("test", Result.where(id: 3).first.metadata["vulnerabilities"].first["key_suffix"])
    # Check that the vulnerablity was opened
    assert_equal("Open", Result.where(id: 3).first.metadata["vulnerabilities"].first["status"])

    #
    # Vulnerablity Counter Assertions
    # 33.84 1613

    # assert 2 open issues
    assert_equal(2, Result.where(id: 3).first.metadata["vulnerability_count"]["open"])
    # assert github sourced
    assert_equal(2, Result.where(id: 3).first.metadata["vulnerability_count"]["source"]["github"])
    # assert task id
    assert_equal(2, Result.where(id: 3).first.metadata["vulnerability_count"]["task_id"]["58"])
    # assert key_suffix
    assert_equal(2, Result.where(id: 3).first.metadata["vulnerability_count"]["key_suffix"]["test"])

  end

  # # Instance Method Tests
  # test "execute has_children method" do
  #   assert_equal(false, fixture_comment.has_children?)
  # end

  # test "execute find_commentable method" do
  #   assert_equal(1, Comment.find_commentable("Result", 1).id)
  # end
end
