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


class SearchProvider::Ebay < SearchProvider::Provider
  def self.provider_name
    "Ebay Search"
  end

  def self.options
    {}
  end

  def initialize(query, options={})
    super
    @access_token = Rails.configuration.try(:ebay_access_key)
  end

  def run
    if(@access_token.blank?)
      Rails.logger.error "Unable to search Ebay. No access token defined. Please define an access key as ebay_access_key in the Scumblr initializer."
      return
    end
    url = URI.escape('http://svcs.ebay.com/services/search/FindingService/v1?OPERATION-NAME=findItemsByKeywords'\
             '&SERVICE-VERSION=1.0.0&SECURITY-APPNAME=' + @access_token + '&'\
             'RESPONSE-DATA-FORMAT=JSON&REST-PAYLOAD&'\
             'keywords=' + @query)
    response = Net::HTTP.get_response(URI(url))
    results = []
    if response.code == "200"
      search_results = JSON.parse(response.body)
      search_results['findItemsByKeywordsResponse'][0]['searchResult'][0]['item'].each do |result|
        results <<
        {
          :title => result['title'].try(:first),
          :url => result['viewItemURL'].try(:first),
          :domain => "ebay.com"
        }
      end
    end
    return results
  end
end
