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

class SearchProvider::Reddit < SearchProvider::Provider
  def self.provider_name
    "Reddit Search"
  end

  def self.options
    {
      :subreddit=>{name: "Search specific subreddit", description: "Search a specific subreddit for this query (or else global)", required: false},
      :results=>{name: "Max results", description: "Max Results", required: false},
      :useragent=>{name: "User-Agent", description: "User-Agent string to present to Reddit", required: false}
    }
  end

  def initialize(query, options={})
    super
        @options[:results] = @options[:results].blank? ? 25 : @options[:results]
	@options[:useragent] = @options[:useragent].blank? ? 'scumblr:search_provider:v0.2.3 by /u/geekspeed' : @options[:useragent]
  end

  def run
    useragent = @options[:useragent]
    if(@options[:subreddit].blank?)
      url = URI.escape('https://www.reddit.com/search.json?q=' + @query  + '&limit=' + @options[:results].to_s)
    else
      url = URI.escape('https://www.reddit.com/r/' + @options[:subreddit] + '/search.json?q=' + @query + '&limit=' + @options[:results].to_s)
    end
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Get.new(uri.request_uri,{'User-Agent' => useragent })
    response = http.request(req)
    results = []
    if response.code == "200"
      search_results = JSON.parse(response.body)
      search_results['data']['children'].each do |result|
	results <<
        {
          :title => result['data']['title'],
          :url => 'https://www.reddit.com' + result['data']['permalink'],
          :domain => "reddit.com"
        }
      end
    end
    return results
  end
end
