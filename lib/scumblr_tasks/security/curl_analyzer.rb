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
require 'shellwords'
require 'posix/spawn'

class ScumblrTask::CurlAnalyzer < ScumblrTask::Async
  include ActionView::Helpers::TextHelper
  include POSIX::Spawn

  def self.task_type_name
    "Curl Analyzer"
  end

  def self.task_category
    "Security"
  end

  def self.description
    "Run curl commands against results and inspect responses for specific regex matches or status code values."
  end

  def self.config_options
    {:timeout_cmd =>{ name: "Timeout Command",
      description: "Shell command to be used to enforce a timeout on curl command (example timeout, gtimeout, etc.)",
      required: false
      }
    }
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
                    description: "Provide newline delimited payloads (exp. paths)",
                    required: false,
                    type: :text},
      :force_port => {name: "Force Port to",
                description: "Specify port for all requests.  This will replace whatever the result was using",
                require: false,
                type: :string},
      :force_protocol => {name: "Force Protocol to",
                          description: "Provide protocol to use for all requests.  Examples are http or https.  This will replace whatever the result currently is using",
                          required: false,
                          type: :string},
      :key_suffix => {name: "Key Suffix",
                      description: "Provide a key suffix for testing out experimental regularz expressions",
                      required: false,
                      type: :string
                      },
      :curl_command => {name: "Curl Command",
                        description: "Provide curl command with url $$result$$ placeholder. Use -i and -v flags for matching headers and status code.",
                        required: true,
                        type: :text
                        },
      :status_code => {name: "HTTP Status Code",
                       description: "Provide HTTP status code to flag result",
                       required: false,
                       type: :string
                       },
      :response_string => {name: "Response String",
                           description: "Provide response string to flag result",
                           required: false,
                           type: :string
                           }
    }
  end

  def initialize(options={})
    # Do setup
    super

    # Check that command is actually curl
    if(@options[:curl_command].split(' ').first != "curl")
      create_event("Command entered isn't curl.")
      raise 'Command entered is not curl!'
      return
    end

    if(@options[:key_suffix].present?)
      @key_suffix = "_" + @options[:key_suffix].to_s.strip
      puts "A key suffix was provided: #{@key_suffix}."
    end

    # A user must supply either a status code or response string to check for
    unless @options[:status_code].present? or @options[:response_string].present?
      create_event("No response string or status code provided")
      raise 'No response string or status code provided.'
      return
    end

    # Parse out all payloads or paths to iterate through when running the curl
    if @options[:payloads].present?
      @payloads = @options[:payloads].to_s.split(/\r?\n/).reject(&:empty?)
    else
      @payloads = [""]
    end

    if(@options[:status_code].present?)
      @status_code = @options[:status_code]
      puts "A status code was provided: #{@status_code}."
    end

    if(@options[:response_string].present?)
      @response_string = @options[:response_string]
      puts "A response string was provided: #{@response_string}."
    else
      @response_string = ""
    end


  end

  def match_environment(r, type, response_data, response_string, status_code=nil, include_status=false, payload=nil)

    vulnerabilities = []
    before = {}
    after ={}
    contents = response_data
    checks = Regexp.new response_string
    # Iterate through each line of the response and grep for the response_sring provided
    contents.each_with_index do |line, line_no|
      begin
        searched_code = checks.match(line.encode("UTF-8", invalid: :replace, undef: :replace))
      rescue
        next
      end
      if searched_code
        puts "----Got Match!----\n"
        puts searched_code.to_s
        vuln = Vulnerability.new

        if(@options[:key_suffix].present?)
          vuln.key_suffix = @options[:key_suffix]
        end
        vuln.source = "curl"
        vuln.task_id = @options[:_self].id.to_s
        vuln.payload = @payload
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
          vuln.type = '"' + response_string + '"' + " - #{type.titleize} Match and #{status_code.to_s} - HTTP Status Code"
          vuln.status_code = status_code.to_s
        else
          vuln.type = '"' + response_string + '"' + " - #{type.titleize} Match"
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
        vuln.url = r.url
        vuln.code_fragment = excerpt(line.chomp, vuln.term, radius: 500)
        vuln.match_location = type
        vuln.before = before
        vuln.after = after
        vuln.line_number = line_no
        vulnerabilities << vuln
      end
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
      puts full_file_path
      attachment = result.result_attachments.new( :attachment=>f, :attachment_file_name=>filename)
      attachment.attachment_content_type="text/plain"
      attachment.save
      puts 'saved attachment'
      f.close
    else
      puts "Attachment already exists."
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

  def perform_work(r)
    # Ensure metadata is defined before iterating results
    r.metadata ||= {}

    @payloads.each do |payload|
      @payload = payload
      request_url = URI.parse(r.url)
      if @options[:force_port].present?
        request_url.port = @options[:force_port].to_i
      end

      if (@options[:force_protocol].present?)
        request_url.scheme = @options[:force_protocol].to_s
      end

      cmd = @options[:curl_command].gsub(/\$\$result\$\$/, "#{request_url.to_s.shellescape}").gsub(/\$\$payload\$\$/, "#{payload.shellescape}").gsub(/\\\r\n/,"")
      cmd = cmd + ' --connect-timeout 8 --max-time 12'
      data = ""
      exit_status = ''
      exit_status_wrapper = ''
      
      # Leverage timeout wrapper for curl command to ensure timeouts
      if @timeout_cmd != ""
        cmd = @timeout_cmd + " 8 " + cmd
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
          # remediate vulnerabilities based on task_id, url, response_string, payload
          r.auto_remediate(@options['_self'].id.to_s, r.url, @response_string, @payload)
          if r.changed?
            r.save!
          end
          return
        end
      rescue
        # Something else happened, so set exit_status to error
        exit_status = 1
      end
      match_update = false
      vulnerabilities = []
      unless exit_status.to_i != 0
        begin
          status_code = data.split(' ')[1]
        rescue => e
          create_event("Could not parse status_code\n Exception: #{e.message}\n#{e.backtrace}", "Warn")
          status_code = 0
        end
        
        # If both status_code and response_string are present, both must match.
        if @status_code.present? and @response_string.present? and @status_code.to_i == status_code.to_i and data.include? (@response_string)

          match_update = true
          *headers, response_body = data.split("\r\n")
          response_body = response_body.split("\n")

          # Check if we have matches in the http response
          response_matches = match_environment(r, "content", response_body, @response_string, status_code, true, payload)
          unless response_matches.empty?
            vulnerabilities.push(*response_matches)
          end

          # Check if we have matches in the http response headers
          header_matches = match_environment(r, "headers", headers, @response_string, status_code, true, payload)
          unless header_matches.empty?
            vulnerabilities.push(*header_matches)
          end

          # Update all vulnerabilities
          r.update_vulnerabilities(vulnerabilities)

          if r.changed?
            upload_s3(r, data)
            r.save!
          end
        # If status_code matches, create a vulnerability
        elsif @response_string.blank? and @status_code.present? and @status_code.to_i == status_code.to_i

          match_update = true
          vuln = Vulnerability.new

          if(@options[:key_suffix].present?)
            vuln.key_suffix = @options[:key_suffix]
          end
          vuln.source = "curl"
          vuln.task_id = @options[:_self].id.to_s
          if @options[:severity].nil?
            vuln.severity = "observation"
          else
            vuln.severity = @options[:severity]
          end

          vuln.type = '"' + status_code.to_s + '"' + " - HTTP Status Code Match"
          vuln.term = status_code.to_s
          vuln.url = r.url
          vuln.payload = @payload

          if vuln.payload.to_s != ""
            vuln.payload = payload
          end
          vuln.match_location = "headers"
          vuln.status_code = status_code.to_s

          r.update_vulnerabilities([vuln])

          if r.changed?
            upload_s3(r, data)
            r.save!
          end
        # If the response string matches expected, create metadata
        elsif @status_code.nil? and @response_string.present? and data.include? (@response_string)
          match_update = true
          *headers, response_body = data.split("\r\n")

          response_body = response_body.split("\n")
          response_matches = match_environment(r, "content", response_body, @response_string, status_code, false, payload)

          unless response_matches.empty?
            vulnerabilities.push(*response_matches)
          end

          header_matches = match_environment(r, "headers", headers, @response_string, status_code, false, payload)
          unless header_matches.empty?
            vulnerabilities.push(*header_matches)
          end

          r.update_vulnerabilities(vulnerabilities)
          if r.changed?
            upload_s3(r, data)
            r.save!
          end
        end

        begin
          # If we didn't find a match, attempt to remediate any existing vulnerabilities
          if match_update == false
            r.auto_remediate(@options['_self'].id.to_s, r.url, @response_string, @payload)
            if r.changed?
              r.save!
            end
          end
        rescue => e
          create_event("Curl warning: #{r.id}.\n\n. Exception: #{e.message}\n#{e.backtrace}", "Warn")
        end
      else
        # We got an exception, check if result changed
        if r.changed?
          r.save!
        end
      end
      puts r.metadata.to_json
    end
  end

  def run
    super
    return
  end

end
