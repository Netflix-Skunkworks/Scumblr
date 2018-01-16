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
    return super.merge({
                         :sync_type => {name: "Sync Type (Organization/User)",
                                        description: "Should this task retrieve repos for an organization or for a user?",
                                        required: false,
                                        type: :choice,
                                        default: :both,
                                        choices: [:org, :user]},
                         :owner => {name: "Organization/User",
                                    description: "Specify the organization or user.",
                                    required: false,
                                    type: :string},
                         :owner_metadata => {name: "Organization/Users from Metadata",
                                             description: "Provide a metadata key to pull organizations or users from.",
                                             required: false,
                                             type: :system_metadata},
                         :members => {name: "Import Organization Members' Repos",
                                      description: "If syncing for an organization, should the task also import Repos owned by members of the organization.",
                                      required: false,
                                      type: :boolean},
                         :tags => {name: "Tag Results",
                                   description: "Provide a tag for newly created results",
                                   required: false,
                                   default: "github",
                                   type: :tag
                                   },
                         :scope_visibility => {name: "Repo Visibility",
                                               description: "Should the task sync public repos, private repos, or both.",
                                               required: true,
                                               type: :choice,
                                               default: :both,
                                               choices: [:both, :public, :private]},

    })
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

    @completed=0
    @last_total = 0

    owners =[]
    if(@options[:owner_metadata])
      begin
        owners = SystemMetadata.find(@options[:owner_metadata]).metadata
      rescue
        owners = []
        create_error("Could not parse System Metadata for users/organizations, skipping")
      end
    end
    owners |= [@options[:owner]] if @options[:owner].present?

    previous_results = @options.try(:[],:_self).try(:metadata).try(:[],"previous_results")
    if(previous_results)
      @last_total = previous_results["created"].to_a.count + previous_results["updated"].to_a.count
    end

    owners.each do |owner|
      puts "Syncing #{owner}"
      get_repos(owner.to_s,@options[:sync_type])

      if(@options[:sync_type] == "org" && @options[:members] == true)
        members = @github.orgs.members.list owner.to_s

        members.each do |m|
          puts "Getting repos for #{m["login"]}"
          get_repos(m["login"],"user")
        end
      end
    end




    return []

  end

  private

  def get_languages(name, repo)
    begin
      response = @github.repos.languages name, repo
    rescue Github::Error::Forbidden=>e
      handle_rate_limit(e)
      retry
    rescue

      return nil
    end
    return response.body
  end

  def get_repos(name, type)

    if(type == "org")
      begin
        response = @github.repos.list org: name
      rescue Github::Error::Forbidden=>e

        retry

      end
    else
      begin

        response = @github.repos.list user: name
      rescue Github::Error::Forbidden=>e
        handle_rate_limit(e)
        retry
      rescue => e

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


        res = Result.where(url: repo.html_url.downcase).first_or_initialize

        res.title = repo.full_name.to_s + " (Github)"
        res.domain = "github.com"
        res.metadata ||={}
        #search_metadata[:github_analyzer] = true

        res.metadata["repository_data"] ||= {}
        res.metadata["repository_data"]["name"] = repo["name"]
        res.metadata["repository_data"]["slug"] = repo["name"]
        res.metadata["repository_data"]["project"] = repo["owner"]["login"]
        res.metadata["repository_data"]["project_name"] = repo["owner"]["login"]
        res.metadata["repository_data"]["project_type"] = repo["owner"]["type"] == "User" ? "User" : "Project"
        res.metadata["repository_data"]["private"] = repo["private"]
        res.metadata["repository_data"]["source"] = "github"
        res.metadata["repository_data"]["ssh_clone_url"] = "ssh://github.com/#{repo["full_name"]}.git"
        res.metadata["repository_data"]["https_clone_url"] = repo["html_url"].to_s + ".git"
        res.metadata["repository_data"]["link"] = repo["html_url"]
        res.metadata["repository_data"]["repository_host"] = @github_api_endpoint.gsub(/\Ahttps?:\/\//,"").gsub(/\/.+/,"")

        # Add programming language metadata including primary language as well as language per LOC
        if repo["language"].present?
          res.metadata["repository_data"]["primary_language"] = repo["language"]
        end

        languages = get_languages(repo["owner"]["login"], repo["name"])

        if languages.present?
          res.metadata["repository_data"]["languages"] = languages.to_hash
        end


        res.save if res.changed?
        begin
          # capture validation exception which is non-breaking
          if @options[:tags].present?
            res.add_tags(@options[:tags])
          end
        rescue Exception => e
          create_event("result: #{res.id}, tags: #{@options[:tags]}, message: #{e}", "Warn")
        end

        @completed += 1
        if(@completed % 10 == 0)
          if(@last_total != 0)
            update_sidekiq_status("Processing #{@last_total} results.  (#{@completed}/#{@last_total} completed)", @completed, @last_total)
          else
            update_sidekiq_status("Syncing stash for first time.  (#{@completed} completed)")
          end
        end
      end
    end
  end


end
