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
#This task will download a repo via git or scraping depotsearch then run a scanner (or scanners) on it

# Prioritize Brakeman Pro if available.
# begin
#   require 'brakeman-pro'
# rescue Gem::LoadError
#   require 'brakeman'
# end

require 'bundler/audit/scanner'
require 'shellwords'
require 'find'

class ScumblrTask::RailsAnalyzer < ScumblrTask::Base
  include POSIX::Spawn
  def self.task_type_name
    "Rails Analyzer"
  end

  def self.task_category
    "Security"
  end

  def self.options
    return super.merge({
                         :saved_result_filter=> {name: "Result Filter",
                                                 description: "Only run endpoint analyzer matching the given filter",
                                                 required: false,
                                                 type: :saved_result_filter
                                                 },
                         :key_suffix => {name: "Key Suffix",
                                         description: "Provide a key suffix for testing out experimental regular expressions",
                                         required: false,
                                         type: :string
                                         },
                         :confidence_level => {name: "Confidence Level",
                                               description: "Confidence level to include in results",
                                               required: false,
                                               type: :choice,
                                               default: :High,
                                               choices: [:High, :Medium, :Weak, :Informational]
                                               },
                         :severity => {name: "Severity",
                                       description: "Severity to include in results",
                                       required: false,
                                       type: :choice,
                                       default: :High,
                                       choices: [:Critical, :High, :Medium, :Low, :Informational]
                                       }
    })
  end

  def run
    @semaphore = Mutex.new
    # require 'get_process_mem'
    # mem = GetProcessMem.new
    # start_memory = mem.mb
    # @options[:_self].metadata["memory"] = {}
    # @options[:_self].metadata["memory"]["start"] = start_memory
    # @options[:_self].metadata["memory"]["result"] = {}


    @results.each_with_index do |r, index|
      # before_memory = mem.mb
      # @options[:_self].metadata["memory"]["result"][r.id] = {}
      # @options[:_self].metadata["memory"]["result"][r.id]["before"] = before_memory


      Rails.logger.info("[*] Running brakeman on #{r.id}")
      # Rails.logger.info("[*] Memory: #{before_memory}")
      update_sidekiq_status("Processing result: #{r.id}.  (#{index}/#{@total_result_count})", index, @total_result_count)
      perform_work(r)


      # after_memory = mem.mb
      # @options[:_self].metadata["memory"]["result"][r.id]["after"] = after_memory
      # @options[:_self].metadata["memory"]["result"][r.id]["used"] = after_memory - before_memory
      # Rails.logger.info("[*] Done running brakeman on #{r.id}")
      # Rails.logger.info("[*] Memory: #{after_memory}")
    end

    # end_memory = mem.mb
    # @options[:_self].metadata["memory"]["end"] = end_memory
    # @options[:_self].metadata["memory"]["used"] = end_memory - start_memory
    # @options[:_self].save

    return []
  end

  def self.description
    "Downloads Rails projects and runs Brakeman. Creates vulnerabilities for findings"
  end

  def self.config_options
    {:downloads_tmp_dir =>{ name: "Repo Download Location",
                            description: "Location to download repos. Defaults to /tmp/rails_analyzer",
                            required: false
                            }
     }
  end

  def initialize(options={})
    # Do setup
    super

    @temp_path = Rails.configuration.try(:downloads_tmp_dir).to_s.strip
    if @temp_path == ""
      @temp_path = "/tmp"
    end
    @temp_path += "/rails_analyzer/"

    unless File.directory?(@temp_path)
      FileUtils.mkdir_p(@temp_path)
    end
  end

  def get_relevant_source(file_path, line_no)
    the_hits = {}
    before = {}
    after ={}
    matched_line={}
    contents = []
    Rails.logger.info file_path
    if line_no.to_i <= 0 || file_path.strip == ""
      return the_hits
    end

    File.open(file_path) do |file|
      file.each_with_index do |line, index|
        line_index = index + 1
        if(line_index >= (line_no - 3) &&  line_index < (line_no))
          before[line_index] = line.chomp.truncate(255)

        elsif(line_index == line_no)
          matched_line = line.chomp.truncate(255)

        elsif(line_index > (line_no) &&  line_index <= (line_no + 3))
          after[line_index] = line.chomp.truncate(255)
        end
        if(line_index >= line_no+3)
          break
        end

      end
    end

    the_hits = {
      :hit_line_number => line_no,
      :hit_source_line => matched_line,
      :before => before,
      :after => after
    }
  end

  def tokenize_command(cmd)
    res = cmd.split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/).
      select {|s| not s.empty? }.
      map {|s| s.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/,'')}
    return res
  end

  def find_path(root_path, filename, dir_or_filename = 0)
    results = []
    Find.find(root_path) do |path|
      #puts path.split("/")[-1].strip
      if path.split("/")[-1].strip == filename.strip
        if dir_or_filename == 1  && !File.directory?(path)
          results.push path
        elsif dir_or_filename == 2 && File.directory?(path)
          results.push path
        else
          results.push path
        end
      end
    end
    Rails.logger.info "looked for '#{filename}'"
    Rails.logger.info "found '#{results.size}'"
    return results
  end

  def scan_with_brakeman(local_repo_path)
    results = []
    #sometimes there are multiple rails apps in the same repo, or sometimes the rails app isn't
    #at the root of the repo, so we find it before scanning
    paths = find_path(local_repo_path, "app", 2)

    paths.each do |railspath|
      fixedPath = railspath.gsub(/app$/, "")
      #Brakeman throws an error if the app folder doesn't exist, checking for it first
      if Dir.exists?(fixedPath + "/app")
        # Try to run brakeman pro first, if the command doesn't exist we'll run regular brakeman

        begin
          pid, stdin, stdout, stderr = popen4("brakeman-pro", "#{fixedPath}", "-o", "#{fixedPath}/output.json")
        rescue
          status_code = 127
        else
          pid, status = Process::waitpid2(pid)
          status_code = status.exitstatus
          ensure
            [stdin, stdout, stderr].each { |io| io.close if !io.nil? && !io.closed? }
          end



          if(status_code == 127)
            begin
              pid, stdin, stdout, stderr = popen4("brakeman", "#{fixedPath}", "-o", "#{fixedPath}/output.json")
            rescue
              status_code = 127
            else
              pid, status = Process::waitpid2(pid)
              status_code = status.exitstatus
              ensure
                [stdin, stdout, stderr].each { |io| io.close if !io.nil? && !io.closed? }
              end

              if(status_code == 127)
                @no_brakeman_installation ||= false
                create_error("[-] No Brakeman executable found. Make sure brakeman or brakeman-pro is in Scumblr's path. Will continue trying to run bundler audit") unless @no_brakeman_installation
                @no_brakeman_installation = true
              end
            end

            report = File.read("#{fixedPath}/output.json")
            report = JSON.parse(report).merge({"railspath"=>fixedPath})
            results.push report
          else
            create_event("There is no app folder in #{railspath}.", "Warn")

          end
        end
        return results
      end

      def scan_with_bundler_audit(local_repo_path)
        results = []

        paths = find_path(local_repo_path, "Gemfile.lock", 1)

        paths.each do |gemfile_path|
          if gemfile_path.start_with?(@temp_path) && gemfile_path.end_with?("Gemfile.lock")
            scanner = Bundler::Audit::Scanner.new(gemfile_path.strip.gsub("Gemfile.lock", ""))
            res = scanner.scan
            res.each do |issue|
              if issue.is_a?(Bundler::Audit::Scanner::UnpatchedGem)
                vuln = {gem: issue.gem.name, version: issue.gem.version.to_s, title: issue.advisory.title, cve: issue.advisory.cve, cvss_v2: issue.advisory.cvss_v2, details: issue.advisory.description.to_s }
              elsif issue.is_a?(Bundler::Audit::Scanner::InsecureSource)
                vuln = {title: "Remote gem with insecure (non-TLS) URI #{issue.source}", cvss_v2: 5.5, details: "" }
              end
              results.push vuln
            end
          end
        end
        return results
      end

      def perform_work(r)
        if(r.metadata.try(:[],"configuration").try(:[],"brakeman").try(:[],"disabled") == true)
          return nil
        end

        if r.metadata.try(:[], "repository_data").present? && r.metadata["repository_data"].try(:[], "ssh_clone_url").present?
          git_url = r.metadata["repository_data"]["ssh_clone_url"]
        elsif r.metadata.try(:[], "stash").present? && r.metadata["stash"].try(:[], "ssh_url").present?
          git_url = r.metadata["repository_data"].try(:[], "ssh_clone_url")
        else
          create_error("No URL for result: #{r.id.to_s}")
          return nil
        end
        repo_local_path = ""
          Rails.logger.info "Cloning and scanning #{git_url}"
          findings = []
          begin
            @semaphore.synchronize {
              status = Timeout::timeout(600) do
                #download the repo so we can scan it
                #local_repo_path = download_repo(stash_git_url, r.url)
                if git_url != ""
                  tmp_download_folder = r.url.split("/")[3]
                end

                repo_local_path = "#{@temp_path}#{git_url.split('/').last.gsub(/\.git$/,"")}#{r.id}"
                dsd = RepoDownloader.new(git_url, repo_local_path)
                dsd.download
              end
            }
            #Brakeman hangs when scanning some repos, normally a scan takes less than 5 seconds
            #We'll give it a minute before we kill it
            @semaphore.synchronize {
              status = Timeout::timeout(100) do
                scan_with_brakeman(repo_local_path).each do |scan_result|
                  scan_result["warnings"].each do |warning|
                    #Only worry about the confidence level and above that was
                    #chosen by the user
                    confidence_levels = case @options[:confidence_level].to_s
                    when "High"
                      ["High"]
                    when "Medium"
                      ["High", "Medium"]
                    when "Weak"
                      ["High", "Medium", "Weak"]
                    else
                      ["High", "Medium", "Weak", "Info"]
                    end

                    if confidence_levels.include?(warning["confidence"].to_s.strip)
                      vuln = Vulnerability.new
                      vuln.match_location = "fingerprint"
                      vuln.type = warning["warning_type"].to_s
                      vuln.fingerprint = warning["fingerprint"]
                      vuln.source_code_file = warning["file"].to_s
                      vuln.source_code_line = warning["line"].to_s
                      vuln.source_code = get_relevant_source(scan_result["railspath"] + "/" + warning["file"].to_s, warning["line"].to_i)
                      vuln.task_id = @options[:_self].id.to_s
                      if(@options[:key_suffix].present?)
                        vuln.key_suffix = @options[:key_suffix]
                      end

                      vuln.details = warning["message"].to_s

                      if warning["confidence"] == "Info"
                        confidence = "Informational"
                      else
                        confidence = warning["confidence"]
                      end

                      vuln.confidence_level = vuln.severity = confidence
                      vuln.source = "Brakeman"
                      findings.push vuln
                    end
                  end
                end
              end
            }

            @semaphore.synchronize {
              status = Timeout::timeout(10) do
                scan_with_bundler_audit(repo_local_path).each do |scan_result|
                  criticality_levels = []
                  if @options[:severity].to_s == "Critical"
                    criticality_levels = ["Critical"]
                  elsif @options[:severity].to_s == "High"
                    criticality_levels = ["Critical", "High"]
                  elsif @options[:severity].to_s == "Medium"
                    criticality_levels = ["Critical", "High", "Medium"]
                  elsif @options[:severity].to_s == "Low"
                    criticality_levels = ["Critical", "High", "Medium", "Low"]
                  else
                    criticality_levels = ["Critical", "High", "Medium", "Low", "Informational"]
                  end

                  severity = ""
                  if scan_result[:cvss_v2].to_f > 9
                    severity = "Critical"
                  elsif scan_result[:cvss_v2].to_f > 7.5
                    severity = "High"
                  elsif scan_result[:cvss_v2].to_f > 4
                    severity = "Medium"
                  elsif scan_result[:cvss_v2].to_f >  1
                    severity = "Low"
                  else scan_result[:cvss_v2].to_f
                    severity = "Informational"
                  end

                  if criticality_levels.include?(severity)
                    vuln = Vulnerability.new
                    vuln.type = scan_result[:title].to_s
                    vuln.severity = severity
                    vuln.source = "Bundler Audit"
                    vuln.details = scan_result[:details].to_s
                    findings.push vuln
                  end
                end
              end
            }
          rescue Exception => e
            create_event("#{e.message} \n#{e.backtrace}", "Warn")
          ensure
            begin
              r.metadata["rails_analyzer"] = true
              r.metadata["rails_results"] ||= {}
              r.metadata["rails_results"]["latest"] ||= {}
              r.metadata["rails_results"]["git_repo"] = git_url
              r.metadata["rails_results"]["results_date"] = Time.now.to_s
              if findings.present?
                # After we update vulnerabilities, collect a list of vuln ids
                # which are either new or existing.
                begin
                  vuln_ids, vuln_metrics = r.update_vulnerabilities(findings)
                rescue Exception => e
                  create_error("Error in auto-remediation.  Result: #{r.to_s}, findings: #{findings.to_s} MESSAGE: #{e.message} \n#{e.backtrace}")
                  r.save
                  return
                end

                # Loop through the existing vulnerabilities, skip if it's new or existing
                # Vulns that aren't found anymore and were identified with the same task
                # Mark as remedaited.

                r.metadata["vulnerabilities"].each_with_object({}) do |vuln|
                  unless vuln_ids.include? vuln["id"] and vuln["task_id"].to_s == @options[:_self].id.to_s
                    vuln["status"] = "Remediated"
                  end
                end
              end
              r.save
              #now that we're done with it, delete the cloned repo
              if Dir.exists?(repo_local_path)
                FileUtils.rm_rf(repo_local_path)
              end
            rescue Exception => e
              create_error("#{e.message} \n#{e.backtrace}")
            end
          end
      end



    end
