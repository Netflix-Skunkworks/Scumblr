#     Copyright 2016 Netflix, Inc.
#
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.


require 'github_api'


class ScumblrTask::GithubSyncAnalyzer < ScumblrTask::Base
  def self.task_type_name
    "Github Repo Sync"
  end

  def self.task_category
    "Sync"
  end

  def self.description
    "Add results for all github repos for a specific organization or user"
  end

  def self.config_options
    {
      :github_oauth_token => {
        name: "Github Oauth Token",
        description: "Setting this token can provide access to private Github organization(s) or repo(s)",
        required: false
      },
      :github_api_endpoint => {
        name: "Github Endpoint",
        description: "Allow configurable endpoint for Github Enterprise deployments",
        required: false
      }
    }
  end

  def self.options
    {
      :sync_type => {name: "Sync Type (Organization/User)",
                 description: "Should this task retrieve repos for an organization or for a user?",
                 required: false,
                 type: :choice,
                 default: :both,
                 choices: [:org, :user]},
      :owner => {name: "Organization/User",
                  description: "Specify the organization or user.",
                  required: true,
                  type: :string},
      :members => {name: "Import Organization Members' Repos",
                  description: "If syncing for an organization, should the task also import Repos owned by members of the organization.",
                  required: false,
                  type: :boolean},
      :scope_visibility => {name: "Repo Visibility",
                  description: "Should the task sync public repos, private repos, or both.",
                  required: true,
                  type: :choice,
                  default: :both,
                  choices: [:both, :public, :private]}
    }
  end


  def initialize(options={})
    super

    @github_oauth_token = @github_oauth_token.to_s.strip
    @github_api_endpoint = @github_api_endpoint.to_s.strip.empty? ? "https://api.github.com" : @github_api_endpoint

    if(@github_oauth_token.present?)
      @github = Github.new oauth_token: @github_oauth_token, endpoint: @github_api_endpoint
    else
      @github = Github.new endpoint: @github_api_endpoint
    end

    @options[:max_results] = @options[:max_results].to_i

    if @options[:members] == "0"
      @options[:members] = false
    else
      @options[:members] = true
    end

  end

  def run

    get_repos(@options[:owner].to_s,@options[:sync_type])

    if(@options[:sync_type] == "org" && @options[:members] == true)
      members = @github.orgs.members.list @options[:owner].to_s

      members.each do |m|
        puts "Getting repos for #{m["login"]}"
        get_repos(m["login"],"user")
      end
    end


    return []

  end

  private


  def get_repos(name, type)
    if(type == "org")
      begin
        response = @github.repos.list org: name
      rescue Github::Error::Forbidden=>e
        handle_rate_limit(e)
        retry
      end
    else
      begin
        response = @github.repos.list user: name
      rescue Github::Error::Forbidden=>e
        handle_rate_limit(e)
        retry
      end
    end
    parse_results(response)



    while(response.has_next_page?)
      puts "Getting new page"
      response = response.next_page
      parse_results(response)

    end

  end

  def handle_rate_limit(e)
    if e.try(:http_headers).try(:[],:retry_after).present?
      wait_for = e.http_headers["retry_after"].to_i
      puts "Sleeping for #{wait_for}"
      sleep(wait_for + 1) if wait_for.to_i > 0
    elsif(e.try(:http_headers).try(:[],"x-ratelimit-remaining").present? && e.try(:http_headers).try(:[],"x-ratelimit-remaining").to_i <= 1)


      wait_for = e.http_headers["x-ratelimit-reset"].to_i - Time.now.to_i

      puts "Sleeping for #{wait_for}"
      sleep (wait_for + 1) if wait_for.to_i > 0
    else
      create_error("Unknown Github error", "Warn")

    end
  end

  def parse_results(response)
    puts "Rate limit: #{response.headers.ratelimit_remaining} of #{response.headers.ratelimit_limit} remaining. Reset in #{response.response.headers["x-ratelimit-reset"].to_i - DateTime.now.to_i} seconds (#{response.response.headers["x-ratelimit-reset"]})"


    response.each do |repo|
      if(@options[:scope_visibility] == "both" || (repo.private == true && @options[:scope_visibility] == "private") || (repo.private == false && @options[:scope_visibility] == "public"))
        res = Result.where(url: repo.html_url).first_or_initialize
        res.title = repo.full_name
        res.domain = "github.com"
        res.metadata ||={}
        res.metadata["github_analyzer"] ||={}
        res.metadata["github_analyzer"]["owner"] = repo["owner"]["login"]
        res.metadata["github_analyzer"]["language"] = repo["language"]
        res.metadata["github_analyzer"]["private"] = repo["private"]
        res.metadata["github_analyzer"]["account_type"] = repo.owner.type
        res.save
      end
    end




  end


end
