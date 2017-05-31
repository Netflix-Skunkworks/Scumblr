#     Copyright 2014 Netflix, Inc.
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



class ScumblrTask::GithubEventAnalyzer < ScumblrTask::Base
  def self.task_type_name
    "Github Event Analyzer"
  end

  def self.task_category
    "Security"
  end

  def self.options
    # these should be a hash (key: val pairs)
    {
      :github_terms => {name: "System Metadata Github Search Terms",
                        description: "Use system metadata search strings.  Expectes metadata to be in JSON array format.",
                        required: true,
                        type: :system_metadata}
    }
  end

  def initialize(options={})
    super
  end

  def determine_term(config, mapping)
    # Given a config file determine the mapping of the term

  end

  def run
    response = ""
    create_event(@options[:_params][:_body], "Info")
    # begin
    #   response = JSON.parse(@options[:_params][:_body])
    # rescue
    #   puts 'not valid json'
    # end

    # vuln_object = {}
    # vulnerabilities = []
    # vuln = Vulnerability.new
    # url = response["commit"]["repository"]["html_url"]


    # response["findings"].each do |finding|
    #   finding["findings"].each do | content |
    #     require 'byebug'
    #     byebug
    #     puts 1
    #     vuln.url = content["content_urls"]
    #     hits_to_search = content["hits"]
    #     vuln.commit_email = response["commit"]["head_commit"]["committer"]["email"]
    #     vuln.commit_name = response["commit"]["head_commit"]["committer"]["name"]
    #     # determine_term(response["config"], )
    #   end

    # end

    #puts "*****Running with options: " + @options[:_params].to_s

  end

end
