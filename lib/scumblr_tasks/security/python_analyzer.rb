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
#This task will download a repo via git or scraping depotsearch then run a scanner (or scanners) on it
require 'shellwords'
require 'posix/spawn'

class ScumblrTask::PythonAnalyzer < ScumblrTask::Async
  include POSIX::Spawn
  def self.task_type_name
    "Python Analyzer"
  end

  def self.task_category
    "Generic"
  end

  def self.options
    return {
      :saved_result_filter=> {name: "Result Filter",
                              description: "Only run endpoint analyzer matching the given filter",
                              required: true,
                              type: :saved_result_filter
                              },
      #:saved_event_filter => { name: "Event Filter",
      #  description: "Only @results with events matching the event filter",
      #  required: false,
      #  type: :saved_event_filter
      #  },
      :key_suffix => {name: "Key Suffix",
                      description: "Provide a key suffix for testing out expirmental regularz expressions",
                      required: false,
                      type: :string
                      },
      :confidence_level => {name: "Confindance Level",
                            description: "Confindance level to include in results",
                            required: false,
                            type: :choice,
                            default: :High,
                            choices: [:High, :Medium, :Low]
                            },
      :severity_level => {name: "Confindance Level",
                          description: "Confindance level to include in results",
                          required: false,
                          type: :choice,
                          default: :High,
                          choices: [:High, :Medium, :Low]
                          }
    }
  end

  def initialize(options={})
    # Do setup
    super

    @temp_path = '/mnt/data/scumblr/python_analyzer/'

    unless File.directory?(@temp_path)
      FileUtils.mkdir_p(@temp_path)
    end

  end

  def tokenize_command(cmd)
    res = cmd.split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/).
      select {|s| not s.empty? }.
      map {|s| s.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/,'')}
    return res
  end

  def scan_with_bandit(local_repo_path)
    results = []
    #Dir.chdir(local_repo_path) do
    conf_str = ""
    if @options[:confidence_level].to_s.downcase == "low"
      conf_str = "-i"
    elsif @options[:confidence_level].to_s.downcase == "medium"
      conf_str = "-ii"
    else
      cond_str = "-iii"
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
    data = ""
    pid, stdin, stdout, stderr = popen4(*tokenize_command(cmd))
    data += stdout.read
    [stdin, stdout, stderr].each { |io| io.close if !io.closed? }
    process, exit_status_wrapper = Process::waitpid2(pid)
    exit_status = exit_status_wrapper.exitstatus.to_i
    parsed_results = JSON.parse(data.strip) rescue nil
    if !parsed_results.nil?
      results.push parsed_results
    end

    return results
  end

  def perform_work(r)
    repo_local_path = ""
    findings = []
    stash_git_url = ""
    begin
      if r.metadata["depot_analyzer"].nil? || r.metadata["depot_analyzer"]["stash_git_url"].nil?
        create_event("No URL for result: #{r.id.to_s}", "Warn")
      else
        status = Timeout::timeout(600) do
          stash_git_url = r.metadata["depot_analyzer"]["stash_git_url"]
          puts "Cloning and scanning #{stash_git_url}"

          #download the repo so we can scan it
          #local_repo_path = download_repo(stash_git_url, r.url)
          repo_local_path = "#{@temp_path}#{stash_git_url.split('/').last.gsub(/\.git$/,"")}"
          url_parts = r.url.split("/")
          project_base_url = "http://depotsearch.netflix.com/source/xref/stash/#{url_parts[4]}/#{url_parts[6]}"
          dsd = RepoDownloader.new(project_base_url, stash_git_url, repo_local_path)
          dsd.download
        end

        status = Timeout::timeout(600) do
          scan_with_bandit(repo_local_path).each do |scan_result|
            scan_result["results"].each do |issue|
              vuln = Vulnerability.new
              vuln.type = issue["issue_text"].to_s
              vuln.task_id = @options[:_self].id.to_s

              if(@options[:key_suffix].present?)
                vuln.key_suffix = @options[:key_suffix]
              end
              vuln.source_code_file = issue["filename"].to_s
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
        r.metadata["python_results"]["git_repo"] = stash_git_url
        r.metadata["python_results"]["results_date"] = Time.now.to_s
        if !findings.empty?
          r.update_vulnerabilities(findings)
        end
        if r.changed?
          r.save!
        end
      end
      #now that we're done with it, delete the cloned repo
    ensure
      if repo_local_path != "" && Dir.exists?(repo_local_path)
        FileUtils.rm_rf(repo_local_path)
      end
    end

  end

  def run
    super
  end

end
