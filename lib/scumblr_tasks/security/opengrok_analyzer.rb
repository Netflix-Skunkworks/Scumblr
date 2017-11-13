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

require 'uri'
require 'net/http'
require 'json'
require 'rest-client'
require 'open-uri'
require 'time'

class ScumblrTask::OpengrokAnalyzer < ScumblrTask::Base
  def self.task_type_name
    "OpenGrok Code Search"
  end

  def self.task_category
    "Security"
  end

  def self.description
    "Search OpenGrok for specific values and create vulnerabilities for matches"
  end

  def self.config_options
    {:opengrok_url =>{ name: "URL for OpenGrok",
      description: "Provides the url/path of the OpenGrok system to search. Example: http://&lt;opengrok_hostname&gt;/source",
      required: true
      }
    }
  end

  def self.options
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
      :max_results => {name: "Limit search results",
                       description: "Limit search results.",
                       required: true,
                       default: "50",
                       type: :string},
      :search_terms => {name: "Search Strings",
                        description: "Provide newline delimited search strings",
                        required: false,
                        type: :text},
      :file_paths => {name: "File Paths",
                      description: "Provide newline delimited file path strings",
                      required: false,
                      type: :text},
      :json_terms => {name: "JSON Array Strings URL",
                      description: "Provide URL for JSON array of search terms",
                      required: false,
                      type: :string},
      :scope => {name: "Scope search to an opengrok projects",
                 description: "Name of opengrok projects, one per line",
                 required: true,
                 type: :text},
      :language => {name: "Language",
                    description: "Choose the language to search for",
                    required: false,
                    type: :choice,
                    default: :any,
                    choices: [:any, :java, :javascript, :python, :ruby, :scala, :c, :"c++", :"c#"]} #,
      #:files_projects => {name: "Return individual filenames, group by project, or containing repo",
      #                    description: "In the results, return paths to filenames or the repos that contains the file(s)",
      #                    required: true,
      #                    type: :choice,
      #                    default: :repo,
      #                    choices: [:files, :projects, :repos]}
    })
  end

  def initialize(options={})
    super

    @opengrok_url = @opengrok_url.to_s.strip
    # Limit to either github, stash or both
    if @options[:scope].to_s != ""
      @search_scope = @options[:scope].to_s.split(/\r?\n/).reject(&:empty?).map{|x| "project=#{x}"}.join("&")
    end

    @results = []
    @terms = []
    @paths = []
    @total_matches = 0

    # Append a key suffix to metadata results for easier filtering
    if(@options[:key_suffix].present?)
      @key_suffix = "_" + @options[:key_suffix].to_s.strip
      puts "A key suffix was provided: #{@key_suffix}."
    end

    # Set the max results if specified, otherwise default to 200 results
    @options[:max_results] = @options[:max_results].to_i > 0 ? @options[:max_results].to_i : 200

    # Check to make sure either search terms, url  or file_path was provided for search
    unless @options[:search_terms].present? or @options[:json_terms].present? or @options[:file_paths].present? or @options[:language].present?
      create_event("No search terms or file paths provided.")
      raise 'No search terms provided.'
      return
    end

    # If search terms are present, parse them out.
    if @options[:search_terms].present?
      @terms = @options[:search_terms].to_s.split(/\r?\n/).reject(&:empty?)
    end

    # If file paths are present, parse them out.
    if @options[:file_paths].present?
      @paths = @options[:file_paths].to_s.split(/\r?\n/).reject(&:empty?)
    end

    # If a URI is provided, try to parse the JSON array of terms and join
    # with any other search terms provided.
    if @options[:json_terms].present?
      begin
        @terms = @terms + JSON.parse(RestClient.get @options[:json_terms])
      rescue => e
        create_event("Unable to retrieve results for #{@options[:json_terms]}.\n\n. Exception: #{e.message}\n#{e.backtrace}")

      end
    end

    # If for some reason terms are still empty, raise an exception.
    if @terms.empty? && @paths.empty? && !(@options[:language].present? && @options[:language].to_s != "" && @options[:language].to_s != "any")
      create_event("Could not parse search terms or file paths.")
      raise 'Could not parse search terms.'
      return
    end

    # make sure search terms are unique
    @terms.uniq!
  end

  #search for something
  def perform_search(term, path, language)

    tries ||= 2
    search_counter = 0
    # For each scope (user, org, repo) check if the search terms match anything
    puts "Checking #{term} - #{path}"
    encoded_term = URI.encode(term)
    encoded_path = URI.encode(path)
    doc = ""
    begin

      search_url = "#{@opengrok_url}s?n=#{@options[:max_results]}&start=0&sort=relevancy&#{@search_scope}&q=#{encoded_term}&path=#{encoded_path}"
      if !language.nil?
        search_url += "&type=#{language}"
      end
      puts search_url
      # Pull the search results
      doc = Nokogiri::HTML(open(search_url))
      rows = doc.xpath('//div[@id="results"]/table')
    rescue OpenURI::HTTPError => e
      tries -= 1
      response = e.io
      error_code = response.status.first
    rescue => e
      create_event("Unknown error occurred\n\n. Exception: #{e.message}\n#{e.backtrace}")
    end
    # get table rows
    rows = []

    url = ""
    doc.xpath('//div[@id="results"]/table/tr').each_with_index do |row, i|
      vuln = Vulnerability.new
      search_metadata = {}
      # Ignore the Github Mirror for now.
      if row.xpath('td[@class="f"]/a/@href').try(:text).present? and row.xpath('td[@class="f"]/a/@href').try(:text).split('/')[4] != "GM"

        if @options[:files_or_repos] == "files"
          search_metadata[:file_name] = row.xpath('td[@class="f"]/a/@href').try(:text).split('/').last
        else
          search_metadata[:file_name] = row.xpath('td[@class="f"]/a/@href').try(:text).split('/').last
        end

        line_numbers = []
        temp = ''
        begin
          parsed_opengrok_url = URI.parse(@opengrok_url)
          url = "#{parsed_opengrok_url.scheme}://#{parsed_opengrok_url.host}"
          if !((parsed_opengrok_url.scheme == "http" && parsed_opengrok_url.port == 80) || (parsed_opengrok_url.scheme == "https" && parsed_opengrok_url.port == 443))
            url += ":#{parsed_opengrok_url.port}"
          end
          url += "#{row.xpath('td[@class="f"]/a/@href').try(:text)}"
          puts 3
          puts url

          row.xpath('td/tt').each_with_index do |td, j|
            if(@options[:key_suffix].present?)
              vuln.key_suffix = @options[:key_suffix]
            end
            vuln.source = "opengrok"
            vuln.task_id = @options[:_self].id.to_s
            vuln.severity = @options[:severity]

            vuln.term = term
            vuln.path = path
            vuln.file_name = search_metadata[:file_name]
            vuln.url =  "#{@opengrok_url}#{row.xpath('td[@class="f"]/a/@href').first.try(:text)}"

            temp = td
            td.xpath("a").each do |thing|
              line_numbers << thing.text
            end
            if encoded_path.size == 0 && encoded_term.size > 0
              vuln.match_location = "content"
              vuln.type = '"' + term + '"' + " - #{vuln.match_location} match"
              vuln.code_fragment = line_numbers
            elsif encoded_path.size > 0 && encoded_term.size == 0
              vuln.match_location = "path"
              vuln.type = '"' + path + '"' + " - #{vuln.match_location} match"
              vuln.code_fragment = line_numbers

            elsif encoded_path.size > 0 && encoded_term.size > 0
              vuln.match_location = "both"
              vuln.type = '"' + term + '"' + " in " + '"' + path + '"' + " - #{vuln.match_location} match"
              vuln.code_fragment = line_numbers
            end
          end

        rescue => e
          create_event("Warning Exception occurred.\n\n. Exception: #{e.message}\n#{e.backtrace}", "Warn")
          puts e.message
          puts e.backtrace
          next
        end
      else
        next
      end
      new_record = false

      res = Result.where(url: url).first

      if res.present?
        res[:metadata][:opengrok_analyzer] ||= {}
        res[:metadata][:opengrok_analyzer].merge!(search_metadata)
        res.update_vulnerabilities([vuln])
        if res.changed?
          res.save!
        end
      else
        new_record = true
      end

      if new_record
        res = Result.new(:url => url,:title => url,:domain => URI.parse(@opengrok_url).host, :metadata => {:opengrok_analyzer => search_metadata})
        puts res.inspect

        res.save!

        res.update_vulnerabilities([vuln])
        if res.changed?
          res.save!
        end
      end
      search_counter = 0

      # end of xpath iterator
    end
  end

  def run
    # store results in results array
    @results = []
    search_terms = []
    # search_terms is an array of hashes with all permutations of terms and paths entered
    # it essentially makes it an terms AND paths search, terms or paths can be blank
    # then it only searches for the one passed
    if @terms.size == 0 && @paths.size > 0
      @paths.each do |path|
        search_terms.push({term: "", path: path.strip})
      end
    elsif @terms.size > 0 && @paths.size == 0
      @terms.each do |term|
        search_terms.push({term: term.strip, path: ""})
      end
    elsif @terms.size > 0 && @paths.size > 0
      @paths.each do |path|
        @terms.each do |term|
          search_terms.push({term: term.strip, path: path.strip})
        end
      end
    end

    # looks to see if a language is passed in
    if !@options[:language].nil? && @options[:language] != "" && @options[:language].to_s != "any"
      language = @options[:language].to_s.strip
    else
      language = nil
    end

    # loops through the search terms array and performs the searches
    puts "Checking #{search_terms.length.to_s} search terms"
    search_terms.each do |term_and_path|
      term = term_and_path[:term].strip
      path = term_and_path[:path].strip

      perform_search(term, path, language)
    end

    # if there search terms are empty but there is a language we'll just search on the language
    if search_terms.empty? && !language.nil?
      perform_search("", "", language)
    end

    return @results
  end
end
