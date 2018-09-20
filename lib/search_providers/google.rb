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


require 'google/api_client'

class SearchProvider::Google < SearchProvider::Provider

  def self.provider_name
    "Google Search"
  end

  def self.options
    {
      :cx=> {name: "Custom Search ID (cx)",
         description: "Custom search engine id (default searches entire web)",
         required: false
         },
      :site => { name: "Limit to Site",
         description: "Allows limiting to a specific domain",
         required: false
         },
      :days_to_search => { name: "Max result age (days)",
         description: "Limit the age of the searched results (days)",
         required: false
         },
      :max_results => { name: "Max results",
         description: "The maximum number of results to return (Maximum: 100)",
         required: false
         }
    }

  end

  def self.description
    "Search Google to create results"
  end

  def self.config_options
    {:google_developer_key =>{ name: "Google Developer Key",
      description: "This key provides access to the Google API",
      required: true
      },
      :google_cx =>{ name: "Google Custom Search Engine Id (cx)",
      description: "This specifies the custom search engine to use for the search. If this is not specified in configuration it must be specified in the task options below.",
      required: false
      },
      :google_application_name =>{ name: "The name of your application to be sent to Google",
      description: "This specifies the name of your application which Google requests and will be sent with API requests",
      required: false
      },
      :google_application_version =>{ name: "The version of your application to be sent to Google",
      description: "This specifies the version of your application which Google requests and will be sent with API requests.",
      required: false
      }

    }
  end


  def initialize(query, options={})
    super


    @cx = options[:cx].present? ? options[:cx] : @google_cx
    @site_search = options[:site].present? ? options[:site] : nil
    @max_results = options[:max_results].to_i > 0 ? options[:max_results].to_i : 10
    @max_results = @max_results > 100 ? 100 : @max_results
  end


  def run

    if(@cx.blank?)
      Rails.logger.error "Unable to search Google. No cx. Please define a cx as google_cx in the Scumblr initializer or pass in as a search option."
      return []
    end

    results =[]

    client = Google::APIClient.new(:key => @google_developer_key, :authorization => nil, :application_name=>@google_application_name, :application_version=>@google_application_version)

    search = client.discovered_api('customsearch')

    (1..@max_results).step(10) do |offset|


      # Make an API call using a reference to a discovered method.

      parameters = {
        'q' => @query,
        'key' => @google_developer_key,
        'cx' => @cx,
        'siteSearch' => @site_search,
        'start' => offset
      }

      if(@options[:days_to_search].present?)
        parameters['dateRestrict'] = "d#{@options[:days_to_search]}"
      end

      response = client.execute(
        :api_method => search.cse.list,
        :parameters => parameters
      )
      Rails.logger.warn "Response received #{response}"
      results += parse_response(response)

    end

    return results[0..@max_results-1]
  end




  private

  def parse_response(response)
    begin
      results_json = Oj.load(response.body)['items']
      results = []

      results_json.each do |result|
        results << {title: result["title"], url: result["link"], domain: result["displayLink"]}
      end
      results
    rescue
      []
    end
  end
end
