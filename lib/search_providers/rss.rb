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
require 'rss'

class SearchProvider::RSS < SearchProvider::Provider
  def self.provider_name
    "RSS Search"
  end

  def self.options
    {
      :feed_url=>{name: "RSS Feed URL", description: "The location of the RSS feed", required: true},
    }
  end

  def initialize(query, options={})
    super
  end

  def run

    results = []

    url = @options[:feed_url]

    domain = URI.parse(url).try(:host) || "Unknown"
    regex = Regexp.union(@query.split(",").map(&:strip).map{|re| Regexp.new(re, Regexp::IGNORECASE)})
    open(url) do |rss|
      feed = RSS::Parser.parse(rss)
      feed_title = "#{feed.channel.title}"
      feed.items.each do |result|
        
        if(result.title.match(regex) || result.description.match(regex))
          results <<
          {
            :title =>  "#{feed_title}: #{result.title}",
            :url => result.link,
            :domain => domain
          }
        end
      end
      

    end


    
    return results
  end
end
