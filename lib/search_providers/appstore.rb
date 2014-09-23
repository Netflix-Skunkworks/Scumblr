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


require 'uri'
require 'net/http'
require 'json'

class SearchProvider::Appstore < SearchProvider::Provider
  def self.provider_name
    "Apple Store Search"
  end

  def self.options
    {
      :results=>{name: "Max results (200)", description: "Specifiy the number of results to retrieve", required: false},
      :require_all_terms=>{name: "Require all terms", description: "If set to \"true\" will ensure all search terms are contained in result", required: false},
    }
  end

  def initialize(query, options={})
    super
    #Delete blank options (since Rails will save blank string if the option is not specified)
    @options.delete_if {|k, v| v.blank? }
    @options.reverse_merge!({:results=>100, :require_all_terms=>"false"})
    @options[:results] = Integer(@options[:results])


  end

  def run

    url = URI.escape('https://itunes.apple.com/search?media=software&term=' + @query + '&limit=' + @options[:results].to_s)
    response = Net::HTTP.get_response(URI(url))
    results = []
    if response.code == "200"
      search_results = JSON.parse(response.body)
      search_results['results'].each do |result|
        skip_result = false
        if(@options[:require_all_terms] == "true")
          @query.split(" ").each do |term|
            if !result.to_s.match(term)
              skip_result = true
              break
            end
          end
        end

        next if skip_result

        results <<
        {
          :title => result['trackName'],
          :url => result['trackViewUrl'],
          :domain => "itunes.apple.com"
        }
      end
    end
    return results
  end
end
