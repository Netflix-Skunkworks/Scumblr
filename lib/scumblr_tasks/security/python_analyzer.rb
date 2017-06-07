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
require 'shellwords'
require 'posix/spawn'

class ScumblrTask::PythonAnalyzer < ScumblrTask::AsyncSidekiq
  include POSIX::Spawn
  def self.task_type_name
    "Python Analyzer"
  end

  def self.task_category
    "Security"
  end

  def self.worker_class
    return ScumblrWorkers::PythonAnalyzerWorker
  end

  def self.options
    return {
      :saved_result_filter=> {name: "Result Filter",
                              description: "Only run endpoint analyzer matching the given filter",
                              required: true,
                              type: :saved_result_filter
                              },
      :key_suffix => {name: "Key Suffix",
                      description: "Provide a key suffix for testing out experimental regularz expressions",
                      required: false,
                      type: :string
                      },
      :confidence_level => {name: "Confidence Level",
                            description: "Confidence level to include in results",
                            required: false,
                            type: :choice,
                            default: :High,
                            choices: [:High, :Medium, :Low]
                            },
      :severity_level => {name: "Severity Level",
                          description: "Severity level to include in results",
                          required: false,
                          type: :choice,
                          default: :High,
                          choices: [:High, :Medium, :Low]
                          }
    }
  end

  def self.description
    "Downloads python projects and runs Bandit. Creates vulnerabilities for findings"
  end

  def self.config_options
    {:downloads_tmp_dir =>{ name: "Repo Download Location",
      description: "Location to download repos. Defaults to /tmp/python_analyzer",
      required: false
      }
    }
  end

  def initialize(options={})
    # Do setup
    super



  end

  def run
    super
  end

end

class ScumblrWorkers::PythonAnalyzerWorker < ScumblrWorkers::AsyncSidekiqWorker

  def perform_work(result_id)

    r = Result.find(result_id)

    if(r.metadata.try(:[],"configuration").try(:[],"bandit").try(:[],"disabled") == true)
      return nil
    end

    @temp_path = Rails.configuration.try(:downloads_tmp_dir).to_s.strip
    if @temp_path == ""
      @temp_path = "/tmp"
    end
    @temp_path += "/python_analyzer/"

    unless File.directory?(@temp_path)
      FileUtils.mkdir_p(@temp_path)
    end
    repo_local_path = ""
    findings = []
    begin
      unless (r.metadata.try(:[], "repository_data").present? && r.metadata["repository_data"].try(:[], "ssh_clone_url").present?)
        create_error("No  URL for result: #{r.id.to_s}")
      else
        git_url = r.metadata["repository_data"]["ssh_clone_url"]

        status = Timeout::timeout(600) do
          Rails.logger.info "Cloning and scanning #{git_url}"

          repo_local_path = "#{@temp_path}#{git_url.split('/').last.gsub(/\.git$/,"")}#{r.id}"
          Rails.logger.info "Cloning to #{repo_local_path}"
          dsd = RepoDownloader.new(git_url, repo_local_path)
          dsd.download
        end



        status = Timeout::timeout(600) do
        Rails.logger.info "Scanning"

          scan_with_bandit(repo_local_path).each do |scan_result|
          Rails.logger.info "Parsing results"

            scan_result["results"].each do |issue|
            Rails.logger.info "Creating vulnerabilities"
              vuln = Vulnerability.new
              vuln.type = issue["issue_text"].to_s
              vuln.task_id = @options[:_self]

              if(@options[:key_suffix].present?)
                vuln.key_suffix = @options[:key_suffix]
              end
              vuln.source_code_file = issue["filename"].to_s.gsub(@temp_path, "")
              vuln.source_code_line = issue["line_number"].to_s
              vuln.confidence_level = issue["issue_confidence"].to_s
              vuln.severity = issue["issue_severity"].to_s
              vuln.source = "Bandit"
              findings.push vuln
            end
          end
        end


        r.metadata["python_analyzer"] = true
        r.metadata["python_results"] ||= {}
        r.metadata["python_results"]["latest"] ||= {}
        r.metadata["python_results"]["git_repo"] = git_url
        r.metadata["python_results"]["results_date"] = Time.now.to_s
        if !findings.empty?
          r.update_vulnerabilities(findings)
        end
        Rails.logger.info "Updating and saving"

        #if r.changed?
          r.save!
        #end
      Rails.logger.info "Saved"
      end
      #now that we're done with it, delete the cloned repo
    ensure
      Rails.logger.info "Deleting repo"
      if repo_local_path != "" && Dir.exists?(repo_local_path)
        FileUtils.rm_rf(repo_local_path)
      end
    end

    return []
  end

  def tokenize_command(cmd)
    res = cmd.split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/).
      select {|s| not s.empty? }.
      map {|s| s.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/,'')}
    return res
  end

  def scan_with_bandit(local_repo_path)
    results = []

    conf_str = ""
    if @options[:confidence_level].to_s.downcase == "low"
      conf_str = "-i"
    elsif @options[:confidence_level].to_s.downcase == "medium"
      conf_str = "-ii"
    else
      conf_str = "-iii"
    end

    sev_str = ""
    if @options[:severity_level].to_s.downcase == "low"
      sev_str = "-l"
    elsif @options[:severity_level].to_s.downcase == "medium"
      sev_str = "-ll"
    else
      sev_str = "-lll"
    end

    cmd = "bandit #{conf_str} #{sev_str} -r -f json #{local_repo_path.shellescape}"
    Rails.logger.warn "Running cmd: #{cmd}"
    
    
    data = ""
    begin
      pid, stdin, stdout, stderr = popen4(*tokenize_command(cmd))
      data += stdout.read
    rescue
      status_code = 127
    else
      pid, status = Process::waitpid2(pid)
      status_code = status.exitstatus
    ensure
      [stdin, stdout, stderr].each { |io| io.close if !io.nil? && !io.closed? }
    end


    parsed_results = JSON.parse(data.strip) rescue nil
    if !parsed_results.nil?
      results.push parsed_results
    end
    
    return results
  end

end
