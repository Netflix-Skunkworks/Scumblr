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
#
# This class allows you to download a repo by scraping it from depotsearch
# Normally used if you can't get the depot from stash or github
require 'posix/spawn'
require 'git'

class RepoDownloader
  # @top_url: depotsearch URL to start downloading from, will recursively download all files from here
  # @save_location: where to save the downloaded file
  attr_accessor :top_url, :save_location, :repo_url
  # this expects the two required parameters from above
  def initialize(repo_url, save_location)
    @save_location = save_location
    @repo_url = repo_url
  end

  def tokenize_command(cmd)
    res = cmd.split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/).
    select {|s| not s.empty? }.
    map {|s| s.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/,'')}
    return res
  end

  def download_repo_from_git(save_path, repo)
    #Creating a directory path to save repo files in, deletes it if it already exists
    #this can happen if the script crashes somewhere between cloning and deleting after the
    #contents are scanned
    has_ssh_key = true
    res = ""
    pid, stdin, stdout, stderr = popen4("ssh -v git@github.com 2>&1")
    res += stdout.read
    if res =~ /Permission denied/
      has_ssh_key = false
    end
    pid, status = Process::waitpid2(pid)
    [stdin, stdout, stderr].each { |io| io.close if !io.closed? }

    github_token = Rails.configuration.try(:github_oauth_token).to_s.strip
    repo_url_parts = URI.parse(repo)
    if github_token == "" || repo !~ /github.com/
      if has_ssh_key
        repo = repo.gsub(/^#{repo_url_parts.scheme}:\/\//, "ssh://")
      else
        repo = repo.gsub(/^#{repo_url_parts.scheme}:\/\//, "https://")
      end
    else  
      repo = repo.gsub(/#{repo_url_parts.scheme}:\/\//, "https://#{github_token}@")
    end

    if Dir.exists?(save_path)
      FileUtils.rm_r save_path
    end
    #git_clone = "git clone #{repo.shellescape} #{save_path.shellescape}"
    #puts "About to clone: #{git_clone}"
    begin
      g = Git.clone(repo, save_path)
      g.fetch
    rescue => e
      create_event("Unable to clone from Git #{repo}.\n\n. Exception: #{e.message}\n#{e.backtrace}", "Warn")
      return false
    end

    if !Dir.exists?(save_path)
      return nil
    end
    return save_path
  end

  # after this has been properly initialized, you can just call this function and it will download
  # everything recursively
  def download()
    clone_res = nil
    if @repo_url.to_s.strip != "" 
      #puts "#" * 40
      #puts "save location: #{@save_location}"
      #puts "repo url: #{@repo_url}"
      #puts "%" * 40
      clone_res = download_repo_from_git(@save_location, @repo_url)
    end
  end

  def create_event(event, level="Error")
      if(event.respond_to?(:message))
        details = "An error occurred in Repo Download Helper. Error: #{event.try(:message)}\n\n#{event.try(:backtrace)}"
      else
        details = "An error occurred in Repo Download Helper. Error #{event.to_s}"
      end

      if(level == "Error")
        Rails.logger.error details
      elsif(level == "Warn") or (level == "Warning")
        Rails.logger.warn details
      else
        Rails.logger.debug details
      end
      event_details = Event.create(action: level, eventable_type: "Task", source: "Repo Download Helper", details: details)

      @event_metadata = {}
      @event_metadata[level] ||= []
      @event_metadata[level] << event_details.id
      if(Thread.current[:current_task])
        #create an event linking the updated/new result to the task
        Thread.current["current_events"] ||={}
        Thread.current["current_events"].merge!(@event_metadata)
      end
    end

    def create_error(event)
      create_event(event, "Error")
    end
end
