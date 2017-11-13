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
#
require 'shellwords'
require 'posix/spawn'
require 'uri/http'

class ScumblrTask::CurlAnalyzer < ScumblrTask::AsyncSidekiq

  def self.task_type_name
    "Curl Analyzer"
  end

  def self.worker_class
    return ScumblrWorkers::CurlAnalyzerWorker
  end

  def self.task_category
    "Generic"
  end

  def self.options
    return super.merge({
      :severity => {name: "Finding Severity",
                    description: "Set severity to either observation, high, medium, or low",
                    required: true,
                    type: :choice,
                    default: :observation,
                    choices: [:observation, :high, :medium, :low]},
      :saved_result_filter=> {name: "Result Filter",
                              description: "Only run endpoint analyzer matching the given filter",
                              required: false,
                              type: :saved_result_filter
                              },
      :saved_event_filter => { name: "Event Filter",
                               description: "Only @results with events matching the event filter",
                               required: false,
                               type: :saved_event_filter
                               },
      :payloads => {name: "Payload Strings",
                    description: "Provide newline delimieted payloads (exp. paths)",
                    required: false,
                    type: :text},
      :saved_payloads => {name: "System Metadata Payload Strings",
                          description: "Use system metadata payloads to seed your curl analyzer.  Expectes metadata to be in JSON array format.  ",
                          required: false,
                          type: :system_metadata},
      :force_port => {name: "Force Port to",
                      description: "Specify port for all requests.  This will replace whatever the result was using",
                      require: false,
                      type: :string},
      :force_protocol => {name: "Force Protocol to",
                          description: "Provide protocol to use for all requests.  Examples are http or https.  This will replace whatever the result currently is using",
                          required: false,
                          type: :string},
      :key_suffix => {name: "Key Suffix",
                      description: "Provide a key suffix for testing out expirmental regularz expressions",
                      required: false,
                      type: :string
                      },

      :curl_command => {name: "Curl Command",
                        description: "Provide curl command with url $$result$$ or result sitemap $$sitemap$$ placeholder",
                        required: true,
                        type: :text
                        },
      :request_metadata => {name: "Request Metadata",
                            description: "Provide LABEL:REGEX (delimited by :) to store arbitrary metadata based on a regular expression match. One label:regex per line",
                            required: false,
                            type: :text
                            },
      :saved_request_metadata => {name: "System Metadata Request Metadata",
                                  description: "Use system metadata payloads to seed your curl analyzer.  Expects metadata to be in JSON array format. \nProvide LABEL:REGEX (delimited by :) to store arbitrary metadata based on a regular expression match. exp:\n[\"Server\":Server(.*)\",\"Host:Host(.*)\"]",
                                  required: false,
                                  type: :system_metadata},
      :status_code => {name: "HTTP Status Code",
                       description: "Provide HTTP status code to flag result",
                       required: false,
                       type: :string
                       },
      :response_string => {name: "Response String",
                           description: "Provide response string to flag result",
                           required: false,
                           type: :string
                           },
      :negative_match => {name: "Negative Match",
                          description: "Create finding if response string or status code isn't identified",
                          required: false,
                          type: :boolean
                          },
      :strip_last_path => {name: "Strip Path",
                           description: "Toggle to strip last path element in URL or sitemap (exp. http://netflix.com/movie/1234 becomes http://netflix.com/movie/",
                           required: false,
                           type: :boolean
                           },
      :strip_to_hostname => {name: "Strip To Hostname",
                             description: "Toggle to strip strip to hostname only (exp. http://netflix.com/movie/1234 becomes http://netflix.com",
                             required: false,
                             type: :boolean
                             }
      # :sidekiq_worker_queue => {name: "Sidekiq Worker Queue",
      #                        description: "Which Sidekiq queue should async workers run in? (Default: worker)",
      #                        required: false,
      #                        type: :sidekiq_queue

      #                        },
      # :sidekiq_queue => {name: "Sidekiq Queue",
      #                  description: "Which Sidekiq queue should the task run in? (Applies only to parent task, not async workers. Default: async_worker)",
      #                  required: false,
      #                  type: :sidekiq_queue
      #                  },

    })
  end

  def initialize(options={})
    # Do setup
    super

    @options[:visited_urls] = []
    @options[:task_type] = Task.where(id: @options[:_self].id).first.name

    # Check that command is actually curl
    if(@options[:curl_command].split(' ').first != "curl")
      create_event("Command entered isn't curl.")
      raise 'Command entered is not curl!'
      return
    end

    # Parse and validate regular expressions for request metadata
    if @options[:request_metadata].present?
      @options[:request_metadata] = @options[:request_metadata].to_s.split(/\r?\n/).reject(&:empty?)

      @options[:request_metadata].each do | check_expressions |
        unless !!(check_expressions =~ /\w.+\:.*/)
          create_event("Request Metadata doesn't match LABEL:REGEX format: #{check_expressions}")
          raise "Request Metadata doesn't match LABEL:REGEX format: #{check_expressions}"
          return
        end
      end
      @options[:request_metadata].map! { |x| [x.split(':', 2)[0], x.split(':', 2)[1]] }
      @options[:request_metadata] = @options[:request_metadata].to_h
    else
      @options[:request_metadata] = nil
    end

    # Parse and validate regular expressions for system metadata that's request metadata
    if @options[:saved_request_metadata].present?
      begin
        saved_request_metadata = SystemMetadata.where(id: @options[:saved_request_metadata]).try(:first).metadata
      rescue
        saved_request_metadata = nil
        create_event("Could not parse System Metadata for saved reqeust metadata, skipping. \n Exception: #{e.message}\n#{e.backtrace}", "Error")
      end

      unless saved_request_metadata.kind_of?(Array)
        saved_request_metadata = nil
        create_event("System Metadata request metadata should be in array format, exp:\n[\"Server\":Server(.*)\",\"Host:Host(.*)\"]", "Error")
      end

      unless saved_request_metadata.blank?
        saved_request_metadata.each do | check_expressions |
          unless !!(check_expressions =~ /\w.+\:.*/)
            create_event("Request Metadata doesn't match LABEL:REGEX format: #{check_expressions}")
            raise "Request Metadata doesn't match LABEL:REGEX format: #{check_expressions}"
            return
          end
        end
        saved_request_metadata.map! { |x| [x.split(':', 2)[0], x.split(':', 2)[1]] }
        saved_request_metadata = saved_request_metadata.to_h
        if @options[:request_metadata].present?
          @options[:request_metadata].concat(saved_request_metadata)
          @options[:request_metadata] = @options[:request_metadata].reject(&:blank?)
        else
          @options[:request_metadata] = saved_request_metadata
          #@options[:request_metadata] = @options[:request_metadata].reject(&:blank?)
        end
      end
    end



    unless(@options[:curl_command].include? "$$result$$" or @options[:curl_command].include? "$$sitemap$$")
      create_event("Command entered doesn't specify a $$result$$ or $$sitemap$$ placeholder")
      raise "Command entered doesn't specify a $$result$$ or $$sitemap$$ placeholder"
      return
    end

    if(@options[:curl_command].include? "$$result$$" and @options[:curl_command].include? "$$sitemap$$")
      create_event("Command entered should  contain either a $$result$$ or $$sitemap$$  placeholder, but not both!")
      raise "Command entered should only contain either a $$result$$ or $$sitemap$$  placeholder"
      return
    end

    if(@options[:curl_command].include? "$$sitemap$$")
      @options[:sitemap] = true
    else
      @options[:sitemap] = false
    end

    if(@options[:key_suffix].present?)
      @options[:key_suffix] = "_" + @options[:key_suffix].to_s.strip
      # puts "A key suffix was provided: #{@options[:key_suffix]}."
    end

    # A user must supply either a status code or response string to check for
    unless @options[:status_code].present? or @options[:response_string].present? or @options[:request_metadata].present?
      create_event("No response string, status code, request metadata provided")
      raise 'No response string, status code, or request metadata provided.'
      return
    end

    # Parse out all paylods or paths to iterate through when running the curl
    if @options[:payloads].present?
      @options[:payloads] = @options[:payloads].to_s.split(/\r?\n/).reject(&:empty?)
    else
      @options[:payloads] = [""]
    end


    @options[:response_string] ||= ""


    if(@options[:negative_match].to_i == 1)
      @options[:negative_match] = true
      # puts "Search will use negative match."
    else
      @options[:negative_match] = false
    end

    if(@options[:strip_last_path].to_i == 1)
      @options[:strip_last_path] = true
      # puts "Search will strip the last path element in the url."
    else
      @options[:strip_last_path] = false
    end

    if(@options[:strip_to_hostname].to_i == 1)
      @options[:strip_to_hostname] = true
    else
      @options[:strip_to_hostname] = false
    end

    if(@options[:saved_payloads].present?)
      begin
        saved_payloads = SystemMetadata.where(id: @options[:saved_payloads]).try(:first).metadata
      rescue
        saved_payloads = nil
        create_event("Could not parse System Metadata for saved payloads, skipping. \n Exception: #{e.message}\n#{e.backtrace}", "Error")
      end

      unless saved_payloads.kind_of?(Array)
        saved_payloads = nil
        create_event("System Metadata payloads should be in array format, exp: [\"foo\", \"bar\"]", "Error")
      end

      # If there are staved payloads, load them.
      if saved_payloads.present?
        @options[:payloads].concat(saved_payloads)
        @options[:payloads] = @options[:payloads].reject(&:blank?)
      end

    end
  end





  def run
    initialize_trends("open_vulnerability_count", ["open"], {legend: {display: true}}, {"open" =>{"steppedLine"=> true}})
    initialize_trends("scan_results", ["new", "existing", "regression", "reopened","closed"], {},  {
                    "new" => {"backgroundColor"=>"#990000", "borderColor"=>"#990000"},
                    "existing" => {"backgroundColor"=>"#999", "borderColor"=>"#999"},
                    "regression" => {"backgroundColor"=>"#ef6548", "borderColor"=>"#ef6548"},
                    "reopened" => {"backgroundColor"=>"#fc8d59", "borderColor"=>"#fc8d59"},
                    "closed" => {"backgroundColor"=>"#034e7b", "borderColor"=>"#034e7b"}
    }, {"date_format"=>"%b %d %Y %H:%M:%S.%L"})

    super

    return
  end

end


def initialize_trends(primary_key, sub_keys, chart_options={}, series_options=[], options={})
  # @chart_options ||= {}
  # @series_options ||= {}
  # @trend_options ||={}
  # Sidekiq.redis do |redis|
  #   Array(sub_keys).each do |k|
  #     redis.set "#{primary_key}:#{k}:value", 0
  #   end
  # end

  # @chart_options[primary_key] = chart_options
  # @series_options[primary_key] = series_options
  # @trend_options[primary_key] = options

end

class ScumblrWorkers::CurlAnalyzerWorker < ScumblrWorkers::AsyncSidekiqWorker
  include ActionView::Helpers::TextHelper
  include POSIX::Spawn

  def perform_work(r)
    # Ensure metadata is defined before iterating results
    if(r.present?)
        r = Result.find(r)
    end

    if(@options["_self"].present?)
      @options["_self"] = Task.find(@options["_self"])
    end

    r.metadata ||= {}

    curl_runner(r)
  end

  def request_metadata_parser(r, response, request_url, request_metadata, metadata_checks)
    curl_metadata = {}
    r.metadata[:curl_metadata] = {}
    terms_matched = []
    response.each_with_index do |line, line_no|
      metadata_checks.each_with_index do |check, key_no|
        begin
          searched_code = check.match(line.encode("UTF-8", invalid: :replace, undef: :replace))
        rescue => e
          next
        end

        if searched_code
          # puts "----Collected Metadata!----\n"
          if searched_code[1].nil?
            matched_expression = searched_code.to_s
          else
            matched_expression = searched_code[1].to_s
          end

          curl_metadata[request_metadata.keys[key_no]] ||= []
          curl_metadata[request_metadata.keys[key_no]] << matched_expression.strip.truncate(300)
          curl_metadata[request_metadata.keys[key_no]].uniq!
          curl_metadata[request_metadata.keys[key_no]]
        end
      end
        r.metadata[:curl_metadata].merge!(curl_metadata)
    end
  end

  def match_environment(r, type, response_data, response_string, request_url, status_code=nil, include_status=false, payload=nil)

    vulnerabilities = []
    before = {}
    after ={}
    contents = response_data
    checks = Regexp.new response_string
    matches = false
    # Iterate through each line of the response and grep for the response_sring provided
    contents.each_with_index do |line, line_no|
      begin
        searched_code = checks.match(line.encode("UTF-8", invalid: :replace, undef: :replace))
      rescue
        next
      end
      if(searched_code)
        matches = true
      end

      if searched_code && !@options[:negative_match]
        # puts "----Got Match!----\n"
        # puts searched_code.to_s
        vuln = Vulnerability.new

        if(@options[:key_suffix].present?)
          vuln.key_suffix = @options[:key_suffix]
        end
        vuln.source = "curl"
        vuln.task_id = @options[:_self].id
        vuln.type = @options[:task_type]
        vuln.payload = payload
        if vuln.payload.to_s != ""
          vuln.payload = payload
        end

        if @options[:severity].nil?
          vuln.severity = "observation"
        else
          vuln.severity = @options[:severity]
        end

        # Check where the match was identified (headers or response)
        if include_status
          vuln.details = '"' + response_string + '"' + " - #{type.titleize} Match and #{status_code.to_s} - HTTP Status Code"
          vuln.status_code = status_code.to_s
        else
          vuln.details = '"' + response_string + '"' + " - #{type.titleize} Match"
          vuln.status_code = status_code.to_s
        end

        case line_no
        when 0
          before = nil
          after = {line_no + 1 => truncate(contents[line_no + 1], length: 500), line_no + 2 => truncate(contents[line_no + 2], length: 500), line_no + 3 => truncate(contents[line_no + 3,], length: 500)}
        when 1
          before = {line_no - 1 => truncate(contents[line_no - 1], length: 500)}
          after = {line_no + 1 => truncate(contents[line_no + 1], length: 500), line_no + 2 => truncate(contents[line_no + 2], length: 500), line_no + 3 => truncate(contents[line_no + 3,], length: 500)}
        when 2
          before = {line_no - 1 =>  truncate(contents[line_no - 1], length: 500), line_no - 2 =>  truncate(contents[line_no - 2], length: 500)}
          after = {line_no + 1 => truncate(contents[line_no + 1], length: 500), line_no + 2 => truncate(contents[line_no + 2], length: 500), line_no + 3 => truncate(contents[line_no + 3,], length: 500)}
        when contents.length
          after = nil
          before = {line_no - 1 => truncate(contents[line_no - 1], length: 500), line_no - 2 => truncate(contents[line_no - 2], length: 500), line_no - 3 => truncate(contents[line_no - 3,], length: 500)}
        when contents.length - 1
          after = {line_no + 1 => truncate(contents[line_no + 1], length: 500)}
          before = {line_no - 1 => truncate(contents[line_no - 1], length: 500), line_no - 2 => truncate(contents[line_no - 2], length: 500), line_no - 3 => truncate(contents[line_no - 3,], length: 500)}
        when contents.length - 2
          after = {line_no + 1 => truncate(contents[line_no + 1], length: 500), line_no + 2 => truncate(contents[line_no + 2])}
          before = {line_no - 1 => truncate(contents[line_no - 1], length: 500), line_no - 2 => truncate(contents[line_no - 2], length: 500), line_no - 3 => truncate(contents[line_no - 3,], length: 500)}
        else
          before = {line_no - 1 => truncate(contents[line_no - 1], length: 500), line_no - 2 => truncate(contents[line_no - 2], length: 500), line_no - 3 => truncate(contents[line_no - 3,], length: 500)}
          after = {line_no + 1 => truncate(contents[line_no + 1], length: 500), line_no + 2 => truncate(contents[line_no + 2], length: 500), line_no + 3 => truncate(contents[line_no + 3,], length: 500)}
        end
        vuln.term = searched_code.to_s
        vuln.url = request_url.to_s
        vuln.code_fragment = excerpt(line.chomp, vuln.term, radius: 500)
        vuln.match_location = type
        vuln.before = before
        vuln.after = after
        vuln.line_number = line_no
        vulnerabilities << vuln

      end
    end
    if @options[:negative_match] and matches == false

      vuln = Vulnerability.new

      if(@options[:key_suffix].present?)
        vuln.key_suffix = @options[:key_suffix]
      end
      vuln.source = "curl"
      vuln.task_id = @options[:_self].id
      vuln.type = @options[:task_type]
      vuln.payload = payload
      if vuln.payload.to_s != ""
        vuln.payload = payload
      end

      if @options[:severity].nil?
        vuln.severity = "observation"
      else
        vuln.severity = @options[:severity]
      end

      if include_status
        # Check where the match was identified (headers or response)
        vuln.details = '"' + response_string + '"' + " - #{type.titleize} Negative Match and #{status_code.to_s} - Negative HTTP Status Code"
        vuln.status_code = status_code.to_s
      else
        vuln.details = '"' + response_string + '"' + " - #{type.titleize} Negative Match"
        vuln.status_code = status_code.to_s
      end

      vuln.term = response_string.to_s
      vuln.url =  request_url.to_s
      vuln.code_fragment = ""
      vuln.match_location = ""
      vuln.before = ""
      vuln.after = ""
      vuln.line_number = ""
      vuln.negative = true
      vulnerabilities << vuln
    end

    return vulnerabilities
  end

  def all_eof(files)
    files.find { |f| !f.eof }.nil?
  end

  def upload_s3(result, response)
    # Upload full http response to s3 bucket
    filename = "task_" + @options["_self"].id.to_s  + "_response_" + result.id.to_s
    full_file_path = "/tmp/#{filename}"
    previous_versions = result.result_attachments.select{|attachment| attachment.attachment_file_name == filename}
    File.write(full_file_path, response)

    if(previous_versions.present?)
      digest = Digest::SHA256.file (full_file_path)
      previous_versions.each do |v|
        if(v.attachment.fingerprint != digest.to_s)
          previous_versions.delete(v)
          v.delete
        end
      end
    end

    if(previous_versions.blank?)
      f = File.open(full_file_path)
      # puts full_file_path
      attachment = result.result_attachments.new( :attachment=>f, :attachment_file_name=>filename)
      attachment.attachment_content_type="text/plain"
      attachment.save
      # puts 'saved attachment'
      f.close
    else
      # puts "Attachment already exists."
    end
    File.delete(full_file_path)
  end

  def tokenize_command(cmd)
    # Prevents command injection on supplied curl command
    res = cmd.split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/).
      select {|s| not s.empty? }.
      map {|s| s.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/,'')}
    return res
  end

  def curl_runner(r, sitemap_url=nil)
    urls = []
    vulnerabilities = []

    if(@options[:sitemap])
      unless r.metadata.try(:[], "sitemap").nil?
        urls = r.metadata["sitemap"].map{ |entry|
          if(@options[:strip_last_path])
            entry["url"].match(/(.+\/\/.+)\/.*/).try(:[], 1) || entry["url"].to_s
          elsif(@options[:strip_to_hostname])
            uri = URI.parse(entry["url"])
            entry["url"].gsub(uri.path, "")
          else
            entry["url"].to_s
          end
        }.uniq
      end
    else
      if(@options[:strip_last_path])
        urls << r.url.to_s.match(/(.+\/\/.+)\/.*/).try(:[], 1) || r.url.to_s
      elsif(@options[:strip_to_hostname])
        uri = URI.parse(r.url.to_s)
        urls << r.url.to_s.gsub(uri.path, "")
      else
        urls << r.url.to_s
      end
    end

    # sort by unique
    urls.uniq!


    urls.each_with_index do |url, index|
      if @options[:visited_urls].include? url
        urls.delete_at(index)
      else
        @options[:visited_urls] << url
      end
    end

    if urls.count == 0
      return
    end
    urls.each do |url|
      puts "[*] Testing url #{url}"
      @options[:payloads].each do |payload|
        request_url = URI.parse(url)

        if @options[:force_port].present?
          request_url.port = @options[:force_port].to_i
        end

        if (@options[:force_protocol].present?)
          request_url.scheme = @options[:force_protocol].to_s
        end


        cmd = @options[:curl_command].gsub(/\$\$result\$\$/, "#{request_url.to_s.shellescape}").gsub(/\$\$sitemap\$\$/, "#{request_url.to_s.shellescape}").gsub(/\$\$payload\$\$/, "#{payload.shellescape}").gsub(/\\\r\n/,"")
        cmd = cmd + ' --connect-timeout 8 --max-time 12'
        data = ""
        exit_status = ''
        exit_status_wrapper = ''
        timeout_cmd = Rails.configuration.try(:timeout_cmd).to_s
        # Leverage timeout wrapper for curl command to ensure timeouts
        if timeout_cmd != ""
          cmd = timeout_cmd + " 12 " + cmd
        end
        pid = 0
        counter = 0

        begin
          # Calls popen4 to run curl command
          pid, stdin, stdout, stderr = popen4(*(tokenize_command(cmd)))

          data += stdout.read

          process, exit_status_wrapper = Process::waitpid2(pid)
          [stdin, stdout, stderr].each { |io| io.close if !io.closed? }


          exit_status = exit_status_wrapper.exitstatus.to_i
          if exit_status == 124
            raise Timeout::Error, "Command #{cmd} timed out"
          end
        rescue Timeout::Error => e
          [stdin, stdout, stderr].each { |io| io.close if !io.closed? }
          # If we timeout, try up to 2 times before skipping
          counter += 1
          if counter < 2
            retry
          else
            # Timeout occurred multiple times
            exit_status = -1
          end
        rescue
          [stdin, stdout, stderr].each { |io| io.close if !io.closed? }
          # Something else happened, so set exit_status to error
          exit_status = -1

        end

        data = data.encode('utf-8', :invalid => :replace, :undef => :replace)
        data = "" if data == nil
        match_update = false
        # vulnerabilities = []
        if exit_status.to_i != 0
          # If we can't make the curl fails we will assume that the vulnerability has been fix (host taken down, etc.)
          # r.auto_remediate(@options['_self'].id.to_s, request_url.to_s, @options[:response_string], payload)
          # return
        else

          begin
            if(data[8..12].to_s.match(/\s\d{3}\s/))
              status_code = data[9..11]
            else
              status_code = 0
            end
          rescue => e
            create_event("Could not parse status_code\n Exception: #{e.message}\n#{e.backtrace}", "Warn")
            status_code = 0
          end


          if @options[:request_metadata]
            response = data.split("\n")

            # Make union of regex's
            #metadata_checks = Regexp.union(@options[:request_metadata].map {|key,val| Regexp.new val.strip})

            metadata_checks = @options[:request_metadata].map {|key,val| Regexp.new val.strip}

            request_metadata_parser(r, response, request_url, @options[:request_metadata], metadata_checks)
          end
          # If both status_code and response_string are present, both must match.

          # Modified to support negative match (sb)
          if @options[:status_code].present? and @options[:response_string].present? and @options[:status_code].to_i == status_code.to_i
            # Disabled because this woudn't flag regex response strings...
            # if @options[:status_code].present? and @options[:response_string].present? and @options[:status_code].to_i == status_code.to_i and data.include? (@options[:response_string])

            *headers, response_body = data.split("\r\n")
            response_body = response_body.split("\n")

            # Check if we have matches in the http response
            # take into consideration negative match operations
            if @options[:negative_match]
              response_matches = match_environment(r, "response", data.split("\n"), @options[:response_string], request_url, status_code, true, payload)
              unless response_matches.empty?
                match_update = true
                vulnerabilities.push(*response_matches)
              end
            else
              response_matches = match_environment(r, "content", response_body, @options[:response_string],  request_url, status_code, true, payload)
              unless response_matches.empty?
                match_update = true
                vulnerabilities.push(*response_matches)
              end

              # Check if we have matches in the http response headers
              header_matches = match_environment(r, "headers", headers, @options[:response_string],  request_url, status_code, true, payload)
              unless header_matches.empty?
                match_update = true
                vulnerabilities.push(*header_matches)
              end
            end

            # Update all vulnerablities
            # r.update_vulnerabilities(vulnerabilities)

            # If status_code matches, create a vulnerability
          elsif @options[:response_string].to_s == "" and @options[:status_code].present? and @options[:status_code].to_i == status_code.to_i

            match_update = true
            vuln = Vulnerability.new

            if(@options[:key_suffix].present?)
              vuln.key_suffix = @options[:key_suffix]
            end
            vuln.source = "curl"
            vuln.task_id = @options[:_self].id
            vuln.type = @options[:task_type]
            if @options[:severity].nil?
              vuln.severity = "observation"
            else
              vuln.severity = @options[:severity]
            end

            if @options[:negative_match]
              vuln.details = '"' + status_code.to_s + '"' + " - Negative HTTP Status Code Match"
            else
              vuln.details = '"' + status_code.to_s + '"' + " - HTTP Status Code Match"
            end
            vuln.term = status_code.to_s
            vuln.url = request_url.to_s
            vuln.payload = payload

            if vuln.payload.to_s != ""
              vuln.payload = payload
            end
            vuln.match_location = "headers"
            vuln.status_code = status_code.to_s
            vulnerabilities << vuln
            # r.update_vulnerabilities([vuln])
            # If the response string matches expected, create metadata
          elsif @options[:status_code].to_s == "" and @options[:response_string].present?

            *headers, response_body = data.split("\r\n")
            response_body = response_body.split("\n")

            if @options[:negative_match]
              response_matches = match_environment(r, "response", data.split("\n"), @options[:response_string],  request_url, status_code, true, payload)
              unless response_matches.empty?
                match_update = true
                vulnerabilities.push(*response_matches)
              end
            else
              response_matches = match_environment(r, "content", response_body, @options[:response_string],  request_url, status_code, true, payload)
              unless response_matches.empty?
                match_update = true
                vulnerabilities.push(*response_matches)
              end

              # Check if we have matches in the http response headers
              header_matches = match_environment(r, "headers", headers, @options[:response_string],  request_url, status_code, true, payload)
              unless header_matches.empty?
                match_update = true
                vulnerabilities.push(*header_matches)
              end
            end
          end

          if r.changed?
            begin
              upload_s3(r, data)
            rescue=>e
              create_error("Could not create S3 attachment for Result #{r.id} #{e.message} #{e.backtrace}")
            end
          end

        end

      end
    end



    # Track not-vulnerable results too.
    counts = r.add_scan_vulnerabilities(vulnerabilities, [], "Curl: #{@options[:task_type]}", @options[:_self].id, true, {isolate_vulnerabilities: true})
    open_count = ["new", "existing", "regression", "reopened"].sum{|type| counts[type].to_i }
    update_trends("open_vulnerability_count", {"open" =>open_count})

    counts["closed"] *= -1
    update_trends("scan_results", counts)


  end

end
