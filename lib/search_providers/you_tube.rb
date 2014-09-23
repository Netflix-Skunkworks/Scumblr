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


require 'rubygems'
require 'google/api_client'
require 'uri'

class SearchProvider::YouTube < SearchProvider::Provider
  def self.provider_name
    "YouTube Search"
  end


  def self.options
    {
      :results=>{name: "Max results", description: "Max Results", required: false}
    }
  end

  def initialize(query , options={})
    super
    @youtube_developer_key = Rails.configuration.try(:youtube_developer_key)
    @youtube_api_service_name = "youtube"
    @youtube_api_version = "v3"
    @application_name = Rails.configuration.try(:youtube_application_name)
    @application_version = Rails.configuration.try(:youtube_application_version)
    @options[:results] = @options[:results].blank? ? 50 : @options[:results]

  end

  def run
    if(@youtube_developer_key.blank?)
      Rails.logger.error "Unable to search YouTube. No developer key. Please define an developer key as youtube_developer_key in the Scumblr initializer."
      return []
    end

    client = Google::APIClient.new(:key => @youtube_developer_key, :authorization => nil, :application_name=>@application_name, :application_version=>@application_version)
    youtube = client.discovered_api(@youtube_api_service_name, @youtube_api_version)
    parameters = {
      'q' => @query,
      'maxResults' => @options[:results],
      'part' => 'id,snippet'
    }
    search_response = client.execute!(
      :api_method => youtube.search.list,
      :parameters => parameters
    )
    results = []


    search_response.data.items.each do |result|
      case result.id.kind
      when 'youtube#video'
        results <<
        {
          title: result.snippet['title'],
          url: "http://youtube.com/watch?v=" + result.id.videoId,
          domain: "youtube.com",
          metadata: {:youtube_id=>result.id.videoId},
          screenshot: result.snippet.thumbnails.high['url'],
          parsed_uri: (result.snippet['description'].nil? ? "" : URI.extract(result.snippet['description'], ['http', 'https']).join(' '))
        }

      end
    end
    return results
  end
end
