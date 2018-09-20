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

class SearchProvider::Github < SearchProvider::Provider
  def self.provider_name
    "Github Repository Search (Legacy)"
  end

  def self.options

    {
      :type=>{name: "Search type ('repositories' (default), 'code', 'issues', 'users')", description: "Specifies which type of search to perform", required: false}
    }

  end

  def self.description
    "(Deprecated) Search Github for repositories, code, issues, or users matching the given query."
  end

  def initialize(query, options={})
    super
    @options[:type] = @options[:type].blank? ? "repositories" : @options[:type]
  end



  def run

    case @options[:type].to_s
      when "repositories", "code", "issues", "users"
        url = URI.escape('https://api.github.com/search/' + @options[:type].to_s + '?q=' + @query)
      else
        Rails.logger.error "Did not recognize this type of search. Please choose 'repositories', 'code', 'issues' or 'users'. Leave blank for the default (repositories)"
        return []
    end
    response = Net::HTTP.get_response(URI(url))
    results = []
    puts "Response: #{response.inspect}"
    if response.code == "200"
      search_results = JSON.parse(response.body)
      search_results['items'].each do |result|
        results <<
        {
          :title => result['name'],
          :url => result['html_url'],
          :domain => "github.com"
        }
      end
    end
    return results
  end


end
