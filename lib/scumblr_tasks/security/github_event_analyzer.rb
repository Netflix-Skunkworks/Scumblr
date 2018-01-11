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
require 'rest-client'
require 'base64'

class ScumblrTask::GithubEventAnalyzer < ScumblrTask::Base
  include ActionView::Helpers::TextHelper
  def self.task_type_name
    "Github Event Analyzer"
  end

  def self.task_category
    "Security"
  end

  def self.callback_task?
    true
  end

  def self.config_options
    {
      :github_oauth_token => {
        name: "Github Oauth Token",
        description: "Setting this token can provide access to private Github organization(s) or repo(s)",
        required: false
      }
    }
  end

  def self.options
    # these should be a hash (key: val pairs)
   return super.merge({
      :severity => {name: "Finding Severity",
                    description: "Set severity to either observation, high, medium, or low",
                    required: true,
                    type: :choice,
                    default: :observation,
                    choices: [:observation, :high, :medium, :low]},
      :key_suffix => {name: "Key Suffix",
                      description: "Provide a key suffix for testing out experimental regular expressions",
                      required: false,
                      type: :string},
      :github_terms => {name: "System Metadata Github Search Terms",
                        description: "Use system metadata search strings.  Expectes metadata to be in JSON array format.",
                        required: true,
                        type: :system_metadata}
    })
  end

  def self.description
    "Receives callback from Github in order to search for a list of terms/regexs in new commits."
  end

  def initialize(options={})
    super
  end


  def match_environment(vuln_url, content_response, hit_hash, regular_expressions, commit_email, commit_name, commit_branch)

    vulnerabilities = []
    before = {}
    after ={}
    regular_expressions_union = Regexp.union(regular_expressions.map {|x| Regexp.new(x.strip)})
    term_counter = {}
    # force encoding fixes issues with ASCII or other weird stuff in source code
    contents = content_response.encode("UTF-8", invalid: :replace, undef: :replace)
    contents = contents.split(/\r?\n|\r/)
    # Iterate through each line of the response and grep for the response_sring provided
    contents.each_with_index do |line, line_no|
      begin
        searched_code = regular_expressions_union.match(line)
      rescue
        next
      end


      if searched_code

        # puts "----Got Match!----\n"
        # puts searched_code.to_s

        term = ""
        details = ""
        matched_term = ""
        regular_expressions.each_with_index do |expression, index|

          if Regexp.new(expression).match(line.encode("UTF-8", invalid: :replace, undef: :replace))
            matched_term = regular_expressions[index]
            break
          end
        end

        hit_hash.each do |hit|

          if matched_term.to_s == hit[:regex]
            term = hit[:name]
            details = '"' + term + '"' + " Match"
          end
        end

        if term_counter[term].to_i < 1
          term_counter[term] = 1

          vuln = Vulnerability.new
          vuln.regex = matched_term
          vuln.source = "github_event"
          vuln.task_id = @options[:_self].id.to_s
          vuln.term = term
          vuln.details = details
          if(@options[:key_suffix].present?)
            vuln.key_suffix = @options[:key_suffix]
          end

          if @options[:severity].nil?
            vuln.severity = "observation"
          else
            vuln.severity = @options[:severity]
          end




          case line_no
          when 0

            before = nil
            after = {line_no + 1 => truncate(contents[line_no + 1].to_s, length: 500), line_no + 2 => truncate(contents[line_no + 2].to_s, length: 500), line_no + 3 => truncate(contents[line_no + 3].to_s, length: 500)}
          when 1
            before = {line_no - 1 => truncate(contents[line_no - 1].to_s, length: 500)}
            after = {line_no + 1 => truncate(contents[line_no + 1].to_s, length: 500), line_no + 2 => truncate(contents[line_no + 2].to_s, length: 500), line_no + 3 => truncate(contents[line_no + 3].to_s, length: 500)}
          when 2
            before = {line_no - 1 =>  truncate(contents[line_no - 1].to_s, length: 500), line_no - 2 =>  truncate(contents[line_no - 2].to_s, length: 500)}
            after = {line_no + 1 => truncate(contents[line_no + 1].to_s, length: 500), line_no + 2 => truncate(contents[line_no + 2].to_s, length: 500), line_no + 3 => truncate(contents[line_no + 3].to_s, length: 500)}
          when contents.length
            after = nil
            before = {line_no - 1 => truncate(contents[line_no - 1].to_s, length: 500), line_no - 2 => truncate(contents[line_no - 2].to_s, length: 500), line_no - 3 => truncate(contents[line_no - 3].to_s, length: 500)}
          when contents.length - 1
            after = {line_no + 1 => truncate(contents[line_no + 1].to_s, length: 500)}
            before = {line_no - 1 => truncate(contents[line_no - 1].to_s, length: 500), line_no - 2 => truncate(contents[line_no - 2].to_s, length: 500), line_no - 3 => truncate(contents[line_no - 3].to_s, length: 500)}
          when contents.length - 2
            after = {line_no + 1 => truncate(contents[line_no + 1].to_s, length: 500), line_no + 2 => truncate(contents[line_no + 2])}
            before = {line_no - 1 => truncate(contents[line_no - 1].to_s, length: 500), line_no - 2 => truncate(contents[line_no - 2].to_s, length: 500), line_no - 3 => truncate(contents[line_no - 3].to_s, length: 500)}
          else
            before = {line_no - 1 => truncate(contents[line_no - 1].to_s, length: 500), line_no - 2 => truncate(contents[line_no - 2].to_s, length: 500), line_no - 3 => truncate(contents[line_no - 3].to_s, length: 500)}
            after = {line_no + 1 => truncate(contents[line_no + 1].to_s, length: 500), line_no + 2 => truncate(contents[line_no + 2].to_s, length: 500), line_no + 3 => truncate(contents[line_no + 3].to_s, length: 500)}
          end

          # vuln.term = searched_code.to_s
          vuln.url = vuln_url
          vuln.file_name = vuln_url.gsub(/blob\/(\w+)\//, "blob/")
          vuln.code_fragment = truncate(line.chomp, length: 500)
          vuln.commit_email = commit_email
          vuln.commit_name = commit_name
          vuln.commit_branch = commit_branch
          vuln.match_location = "file"
          vuln.before = before
          vuln.after = after
          vuln.line_number = line_no
          vulnerabilities << vuln

        else
          term_counter[term] += 1
        end
      end
    end

    vulnerabilities.each do |vuln|
      vuln.match_count = term_counter[vuln.term]
    end
    return vulnerabilities
  end

  def run
    @github_oauth_token = @github_oauth_token.to_s.strip
    response = ""
    begin
      response = JSON.parse(@options[:_params][:_body])
    rescue
      create_event('not valid json')
      raise
    end

    vuln_object = {}
    vulnerabilities = []

    # Step through each finding and it's assocaited contents
    response["findings"].each do |finding|

      finding["findings"].each do | content |
        vuln = Vulnerability.new
        url = response["commit"]["repository"]["html_url"].downcase
        #vuln_url = content["content_urls"]
        hits_to_search = content["hits"]
        commit_email = response["commit"]["head_commit"]["committer"]["email"]
        commit_name = response["commit"]["head_commit"]["committer"]["name"]
        commit_branch = response["commit"]["ref"].split('/').last


        # Step into the finding and create the right things:
        hit_hash = []
        regular_expressions = []

        content["hits"].each do |hit|

          response["config"]["options"]["github_terms"].each do |name,regex|
            if name == hit
              regular_expressions << regex
              hit_hash << {"name": hit, "regex": regex}
            end
          end
        end

        unless @github_oauth_token.blank?

          begin
            content_response = JSON.parse RestClient.get(content["content_urls"] + "?&access_token=#{@github_oauth_token}")
          rescue RestClient::ResourceNotFound
            create_event("Request with access token and got 401. #{content["content_urls"]}?&access_token=#{@github_oauth_token} retrying without access token.", "Warn")
            content_response = JSON.parse RestClient.get(content["content_urls"])
          end
        else
          content_response = JSON.parse RestClient.get(content["content_urls"])
        end

        vuln_url = content_response["html_url"]
        content_response = Base64.decode64(content_response["content"].strip)
        vulnerabilities = match_environment(vuln_url, content_response, hit_hash, regular_expressions, commit_email, commit_name, commit_branch)

        begin

          @res = Result.where(url: url).first
          @res.update_vulnerabilities(vulnerabilities)
        rescue => e
          create_event("Couldn't update vulnerabilities.  Exception: #{e.message}\n#{e.backtrace}")
        end

      end

    end

    @res.save if @res.changed?
    return []
  end

end
