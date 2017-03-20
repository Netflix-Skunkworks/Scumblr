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

class ScumblrTask::CurlAnalyzer < ScumblrTask::Async
  include ActionView::Helpers::TextHelper
  include POSIX::Spawn

  def self.task_type_name
    "Curl Analyzer"
  end

  def self.task_category
    "Generic"
  end

  def self.options
    return {
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
                           }
    }
  end

  def initialize(options={})
    # Do setup
    super

    @task_type = Task.where(id: @options[:_self].id).first.name

    # Check that command is actually curl
    if(@options[:curl_command].split(' ').first != "curl")
      create_event("Command entered isn't curl.")
      raise 'Command entered is not curl!'
      return
    end

    # Parse and validate regular expressions for request metadata
    if @options[:request_metadata].present?
      @request_metadata = @options[:request_metadata].to_s.split(/\r?\n/).reject(&:empty?)

      @request_metadata.each do | check_expressions |
        unless !!(check_expressions =~ /\w.+\:.*/)
          create_event("Request Metadata doesn't match LABEL:REGEX format: #{check_expressions}")
          raise "Request Metadata doesn't match LABEL:REGEX format: #{check_expressions}"
          return
        end
      end
      @request_metadata.map! { |x| [x.split(':', 2)[0], x.split(':', 2)[1]] }
      @request_metadata = @request_metadata.to_h
    else
      @request_metadata = nil
    end

    # Parse and validate regular expressions for system metadata that's request metadata
    if @options[:saved_request_metadata].present?
      begin
        saved_request_metadata = SystemMetadata.where(id: @options[:saved_request_metadata]).try(:first).metadata
      rescue
        saved_request_metadata = nil
        create_event("Could not parse System Metadata for saved reqeust metadatums, skipping. \n Exception: #{e.message}\n#{e.backtrace}", "Error")
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
        if @request_metadata.present?
          @request_metadata.concat(saved_request_metadata)
          @request_metadata = @request_metadata.reject(&:blank?)
        else
          @request_metadata = saved_request_metadata
          #@request_metadata = @request_metadata.reject(&:blank?)
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
      @sitemap = true
    else
      @sitemap = false
    end

    if(@options[:key_suffix].present?)
      @key_suffix = "_" + @options[:key_suffix].to_s.strip
      # puts "A key suffix was provided: #{@key_suffix}."
    end

    # A user must supply either a status code or response string to check for
    unless @options[:status_code].present? or @options[:response_string].present? or @options[:request_metadata].present?
      create_event("No response string, status code, or request metadata provided")
      raise 'No response string, status code, or request metadata provided.'
      return
    end

    # Parse out all paylods or paths to iterate through when running the curl
    if @options[:payloads].present?
      @payloads = @options[:payloads].to_s.split(/\r?\n/).reject(&:empty?)
    else
      @payloads = [""]
    end

    if(@options[:status_code].present?)
      @status_code = @options[:status_code]
      # puts "A status code was provided: #{@status_code}."
    end

    if(@options[:response_string].present?)
      @response_string = @options[:response_string]
      # puts "A response string was provided: #{@response_string}."
    else
      @response_string = ""
    end

    if(@options[:negative_match].to_i == 1)
      @negative_match = true
      # puts "Search will use negative match."
    else
      @negative_match = false
    end

    if(@options[:strip_last_path].to_i == 1)
      @strip_last_path = true
      # puts "Search will strip the last path element in the url."
    else
      @strip_last_path = false
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
        @payloads.concat(saved_payloads)
        @payloads = @payloads.reject(&:blank?)
      end

    end
  end


  def request_metadata_parser(r, response, request_url, request_metadata, metadata_checks)
    curl_metadata ||= {}
    r.metadata[:curl_metadata] ||= {}

    response.each do |line|
      metadata_checks.each_with_index do |check, line_no|

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
          curl_metadata[request_metadata.keys[line_no]] = matched_expression.strip
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

      if searched_code && !@negative_match
        # puts "----Got Match!----\n"
        # puts searched_code.to_s
        vuln = Vulnerability.new

        if(@options[:key_suffix].present?)
          vuln.key_suffix = @options[:key_suffix]
        end
        vuln.source = "curl"
        vuln.task_id = @options[:_self].id.to_s
        vuln.type = @task_type
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
    if @negative_match and matches == false

      vuln = Vulnerability.new

      if(@options[:key_suffix].present?)
        vuln.key_suffix = @options[:key_suffix]
      end
      vuln.source = "curl"
      vuln.task_id = @options[:_self].id.to_s
      vuln.type = @task_type
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
      digest = Digest::MD5.file (full_file_path)
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
    if(@sitemap)
      unless r.metadata.try(:[], "sitemap").nil?
        urls = r.metadata["sitemap"].map{ |entry|
          if(@strip_last_path)
            entry["url"].match(/(.+\/\/.+)\/.*/).try(:[], 1) || entry["url"].to_s
          else
            entry["url"].to_s
          end
        }.uniq
      end
    else
      if(@strip_last_path)
        urls << r.url.to_s.match(/(.+\/\/.+)\/.*/).try(:[], 1) || r.url.to_s
      else
        urls << r.url.to_s
      end
    end

    urls.each do |url|
      # puts "[*] Testing url #{url}"
      @payloads.each do |payload|
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
          cmd = timeout_cmd + " 8 " + cmd
        end

        pid = 0
        counter = 0
        begin
          # Calls popen4 to run curl command
          pid, stdin, stdout, stderr = popen4(*(tokenize_command(cmd)))
          data += stdout.read

          [stdin, stdout, stderr].each { |io| io.close if !io.closed? }
          process, exit_status_wrapper = Process::waitpid2(pid)
          exit_status = exit_status_wrapper.exitstatus.to_i
          if exit_status == 124
            raise Timeout::Error, "Command #{cmd} timed out"
          end
        rescue Timeout::Error => e
          # If we timeout, try up to 2 times before skipping
          counter += 1
          if counter < 2
            retry
          else
            # Timeout occurred multiple times
            exit_status = -1
          end
        rescue
          # Something else happened, so set exit_status to error
          exit_status = -1
        end
        data = data.encode('utf-8', :invalid => :replace, :undef => :replace)

        match_update = false
        # vulnerabilities = []
        if exit_status.to_i != 0
          # If we can't make the curl fails we will assume that the vulnerability has been fix (host taken down, etc.)
          # r.auto_remediate(@options['_self'].id.to_s, request_url.to_s, @response_string, payload)
          # return
        else
          begin
            status_code = data.split(' ')[1]
          rescue => e
            create_event("Could not parse status_code\n Exception: #{e.message}\n#{e.backtrace}", "Warn")
            status_code = 0
          end

          if @request_metadata
            response = data.split("\n")
            # Make union of regex's
            #metadata_checks = Regexp.union(@request_metadata.map {|key,val| Regexp.new val.strip})

            metadata_checks = @request_metadata.map {|key,val| Regexp.new val.strip}

            request_metadata_parser(r, response, request_url, @request_metadata, metadata_checks)
          end
          # If both status_code and response_string are present, both must match.
          # Modified to support negative match (sb)
          if @status_code.present? and @response_string.present? and @status_code.to_i == status_code.to_i
            # Disabled because this woudn't flag regex response strings...
            # if @status_code.present? and @response_string.present? and @status_code.to_i == status_code.to_i and data.include? (@response_string)

            *headers, response_body = data.split("\r\n")
            response_body = response_body.split("\n")

            # Check if we have matches in the http response
            # take into consideration negative match operations
            if @negative_match
              response_matches = match_environment(r, "response", data.split("\n"), @response_string, request_url, status_code, true, payload)
              unless response_matches.empty?
                match_update = true
                vulnerabilities.push(*response_matches)
              end
            else
              response_matches = match_environment(r, "content", response_body, @response_string,  request_url, status_code, true, payload)
              unless response_matches.empty?
                match_update = true
                vulnerabilities.push(*response_matches)
              end

              # Check if we have matches in the http response headers
              header_matches = match_environment(r, "headers", headers, @response_string,  request_url, status_code, true, payload)
              unless header_matches.empty?
                match_update = true
                vulnerabilities.push(*header_matches)
              end
            end

            # Update all vulnerablities
            # r.update_vulnerabilities(vulnerabilities)

            if r.changed?
              upload_s3(r, data)
            end
            # If status_code matches, create a vulnerability
          elsif @response_string.to_s == "" and @status_code.present? and @status_code.to_i == status_code.to_i

            match_update = true
            vuln = Vulnerability.new

            if(@options[:key_suffix].present?)
              vuln.key_suffix = @options[:key_suffix]
            end
            vuln.source = "curl"
            vuln.task_id = @options[:_self].id.to_s
            vuln.type = @task_type
            if @options[:severity].nil?
              vuln.severity = "observation"
            else
              vuln.severity = @options[:severity]
            end

            if @negative_match
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

            if r.changed?
              upload_s3(r, data)
            end
            # If the response string matches expected, create metadata
          elsif @status_code.to_s == "" and @response_string.present?

            *headers, response_body = data.split("\r\n")
            response_body = response_body.split("\n")

            if @negative_match
              response_matches = match_environment(r, "response", data.split("\n"), @response_string,  request_url, status_code, true, payload)
              unless response_matches.empty?
                match_update = true
                vulnerabilities.push(*response_matches)
              end
            else
              response_matches = match_environment(r, "content", response_body, @response_string,  request_url, status_code, true, payload)
              unless response_matches.empty?
                match_update = true
                vulnerabilities.push(*response_matches)
              end

              # Check if we have matches in the http response headers
              header_matches = match_environment(r, "headers", headers, @response_string,  request_url, status_code, true, payload)
              unless header_matches.empty?
                match_update = true
                vulnerabilities.push(*header_matches)
              end
            end

          end

        end

      end
    end
    # Track not-vulnerable results too.
    counts = r.add_scan_vulnerabilities(vulnerabilities, [], "Curl: #{@task_type}", @options[:_self].id, true, {isolate_vulnerabilities: true})
    open_count = ["new", "existing", "regression", "reopened"].sum{|type| counts[type].to_i }
    update_trends("open_vulnerability_count", {"open" =>open_count},{legend: {display: true}}, {"open" =>{"steppedLine"=> true}})

    counts["closed"] *= -1
    update_trends("scan_results", counts, {}, {
                    "new" => {"backgroundColor"=>"#990000", "borderColor"=>"#990000"},
                    "existing" => {"backgroundColor"=>"#999", "borderColor"=>"#999"},
                    "regression" => {"backgroundColor"=>"#ef6548", "borderColor"=>"#ef6548"},
                    "reopened" => {"backgroundColor"=>"#fc8d59", "borderColor"=>"#fc8d59"},
                    "closed" => {"backgroundColor"=>"#034e7b", "borderColor"=>"#034e7b"}
    }, {"date_format"=>"%b %d %Y %H:%M:%S.%L"} )

    if r.changed?
      upload_s3(r, data)
    end
  end

  def perform_work(r)
    # Ensure metadata is defined before iterating results
    curl_runner(r)



  end

  def run
    @trends = {}
    super
    @options[:_self].metadata["latest_results_link"] = {text: "#{@trends.try(:[],"open_vulnerability_count").try(:[],"open").to_i} results", search:"q[metadata_search]=vulnerability_count:task_id:#{@options[:_self].id}>0"}
    save_trends





    return
  end

end
