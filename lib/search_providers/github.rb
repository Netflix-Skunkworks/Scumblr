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

class SearchProvider::Github < SearchProvider::Provider
  def self.provider_name
    "Github Search"
  end

  def self.options
    {
      :type=>{name: "Search type ('repositories' (default), 'code', 'issues', 'users')", description: "Specifies which type of search to perform", required: false},
      :useragent=>{name: "User-Agent", description: "User-Agent string to supply to GitHub. See <a href='https://developer.github.com/v3/#user-agent-required'>https://developer.github.com/v3/#user-agent-required</a> ", required: true},
      :codesearch=>{name: "Code Search Validation", description: "GitHub requires additional options for Code Search. If your search is a code search you need to include at least one of: user, repo, or organization in your search string. More info at <a href='https://developer.github.com/changes/2013-10-18-new-code-search-requirements/'>https://developer.github.com/changes/2013-10-18-new-code-search-requirements/</a>", required: false}
    }
  end

  def initialize(query, options={})
    super
    @options[:type] = @options[:type].blank? ? "repositories" : @options[:type]
    @options[:useragent] = @options[:useragent].blank? ? "Scumblr-Search-Provider" : @options[:useragent]
    @client_id = Rails.configuration.try(:github_client_id) 
    @client_secret = Rails.configuration.try(:github_client_secret)
    @options[:codesearch] = codesearch = @options[:codesearch]
 end

  def run
    if @client_id.blank? || @client_secret.blank?
	nosecret = true
    	Rails.logger.error "No GitHub client_id found, results may be rate limited - or may not work at all. Please visit: https://github.com/settings/applications/new and create an Oauth Application. Once that has comlpeted -  define a client id as github_client_id in the Scumblr initializer."
    end
    case @options[:type].to_s
      when "repositories", "code", "issues", "users"
	if nosecret 
        	url = URI.escape('https://api.github.com/search/' + @options[:type].to_s + '?q=' + @query)	
	else
		url = URI.escape('https://api.github.com/search/' + @options[:type].to_s + '?client_id=' + @client_id + '&client_secret=' + @client_secret + '&q=' + @query)
	end
	if @options[:type].to_s.include? "code"
	# Github adds validations for API based searching of code -- see: https://developer.github.com/changes/2013-10-18-new-code-search-requirements/ 
	#
		codesearch = URI.escape(@options[:codesearch])
		url = url + " " + codesearch
	end
      else
        Rails.logger.error "Did not recognize this type of search. Please choose 'repositories', 'code', 'issues' or 'users'. Leave blank for the default (repositories)"
        return []
    end
    useragent = @options[:useragent]
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Get.new(uri.request_uri,{'User-Agent' => useragent })
    response = http.request(req)

    results = []
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
