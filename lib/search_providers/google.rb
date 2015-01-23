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


require 'google/api_client'

class SearchProvider::Google < SearchProvider::Provider

  def self.provider_name
    "Google Search"
  end

  def self.options
    {
      :cx=> {name: "Custom Search ID (cx)",
             description: "Custom search engine id (default seaches entire web)",
             required: false
             },
      :site => { name: "Limit to Site",
                 description: "Allows limiting to a specific domain",
                 required: false
                 },
      :days_to_search => { name: "Max result age (days)",
                           description: "Limit the age of the searched results (days)",
                           required: false
                           }
    }

  end

  def initialize(query, options={})
    super

    @google_developer_key = Rails.configuration.try(:google_developer_key)
    @cx = options[:cx].present? ? options[:cx] : Rails.configuration.try(:google_cx)
    @application_name = Rails.configuration.try(:google_application_name)
    @application_version = Rails.configuration.try(:google_application_verion)
    @site_search = options[:site].present? ? options[:site] : nil
  end


  def run

    if(@google_developer_key.blank?)
      Rails.logger.error "Unable to search Google. No developer key. Please define an developer key as google_developer_key in the Scumblr initializer."
      return []
    end
    if(@cx.blank?)
      Rails.logger.error "Unable to search Google. No cx. Please define a cx as google_cx in the Scumblr initializer or pass in as a search option."
      return []
    end

    results =[]

    client = Google::APIClient.new(:key => @google_developer_key, :authorization => nil, :application_name=>@application_name, :application_version=>@application_version)

    search = client.discovered_api('customsearch')

    (1..100).step(100) do |offset|


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

    return results
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
