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


class SearchProvider::Ebay < SearchProvider::Provider
  def self.provider_name
    "Ebay Search"
  end

  def self.options
    {}
  end

  def self.description
    "Search eBay to create results"
  end

  def self.config_options
    {:ebay_access_key =>{ name: "eBay Access Key",
      description: "This key provides access to the eBay API",
      required: true
      }
    }
  end

  def initialize(query, options={})
    super
    
  end

  def run
    
    url = URI.escape('http://svcs.ebay.com/services/search/FindingService/v1?OPERATION-NAME=findItemsByKeywords'\
             '&SERVICE-VERSION=1.0.0&SECURITY-APPNAME=' + @ebay_access_key + '&'\
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
