require "test_helper"
require "byebug"
class GithubAnalyzerTest < ActiveSupport::TestCase
  # Load Fixtured Event


  github_term_metadata = SystemMetadata.where(id: 2).first
  github_org_metadata = SystemMetadata.where(id: 3).first

  # Class Method Tests
  test "execute saved github search task with public members" do
    skip("Github OAuth Token not defined") if Rails.configuration.try(:github_oauth_token).blank?
    # This should help with some github stuff
    # and also did it create vulns correctly.
    github_search_fixture = Task.where(id: 58).first
    github_search_fixture.perform_task

    # Return 2 results from test github org
    assert_equal(2, github_search_fixture.metadata[:current_results].count)

    # Check vuln count is correct
    assert_equal(2, Result.where(url: "https://github.com/scumblrminitest/test_repo2").first.metadata["vulnerabilities"].count)
    # check key_suffix is correct
    assert_equal("test", Result.where(url: "https://github.com/scumblrminitest/test_repo2").first.metadata["vulnerabilities"].first["key_suffix"])
    # Check that the vulnerablity was opened
    assert_equal("New", Result.where(url: "https://github.com/scumblrminitest/test_repo2").first.metadata["vulnerabilities"].first["status"])

    #
    # Vulnerablity Counter Assertions
    #

    # assert 2 open issues
    assert_equal(2, Result.where(url: "https://github.com/scumblrminitest/test_repo2").first.metadata["vulnerability_count"]["state"]["open"])
    # assert github sourced
    assert_equal(2, Result.where(url: "https://github.com/scumblrminitest/test_repo2").first.metadata["vulnerability_count"]["source"]["github"])
    # assert task id

    assert_equal(2, Result.where(url: "https://github.com/scumblrminitest/test_repo2").first.metadata["vulnerability_count"]["task_id"]["58"])
    # assert key_suffix
    assert_equal(2, Result.where(url: "https://github.com/scumblrminitest/test_repo2").first.metadata["vulnerability_count"]["key_suffix"]["test"])
  end

  test "execute saved github repo search task" do
    skip("Github OAuth Token not defined") if Rails.configuration.try(:github_oauth_token).blank?
    # This should help with some github stuff
    # and also did it create vulns correctly.
    github_repo_fixture = Task.where(id: 59).first

    github_repo_fixture.perform_task

    # Return 2 results from test github org
    assert_equal(1, github_repo_fixture.metadata[:current_results].count)
  end

  test "execute saved github users search task with bad data" do
    skip("Github OAuth Token not defined") if Rails.configuration.try(:github_oauth_token).blank?
    # This should help with some github stuff
    # and also did it create vulns correctly.
    github_repo_fixture = Task.where(id: 60).first
    github_repo_fixture.perform_task
    # Return 2 results from test github org
    assert_equal("Search Scope is not defined, do the orgs/users you specified actually exist?", Event.last.details)
  end

  test "execute saved github repos search task with bad data" do
    skip("Github OAuth Token not defined") if Rails.configuration.try(:github_oauth_token).blank?
    # This should help with some github stuff
    # and also did it create vulns correctly.
    github_repo_fixture = Task.where(id: 61).first
    github_repo_fixture.perform_task
    # Return 2 results from test github org
    assert_equal("Search Scope is not defined, do the orgs/users you specified actually exist?", Event.last.details)
  end

  test "execute long search with many results and hopefully ratelimits" do
    skip("Github OAuth Token not defined") if Rails.configuration.try(:github_oauth_token).blank?
    # This should help with some github stuff
    # and also did it create vulns correctly.
    # Should result in maximum result limit warning
    github_repo_fixture = Task.where(id: 62).first
    github_repo_fixture.perform_task
    event_github = Event.where(action: "Warn").last.try(:[],"details").include? "Hit maximum results limit"

    # Checks may pages of results, but should result in warning for too many pages of results
    assert_equal(event_github, true)
  end

end
