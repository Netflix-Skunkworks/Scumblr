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
require 'rss'

class SearchProvider::RSS < SearchProvider::Provider
  def self.provider_name
    "RSS Search"
  end

  def self.options
    {
      :feed_url=>{name: "RSS Feed URL", description: "The location of the RSS feed", required: true}
    }
  end

  def initialize(query, options={})
    super
    #Delete blank options (since Rails will save blank string if the option is not specified)
  end

  def self.description
    "Search for matching entry in an RSS feed."
  end

  def run

    results = []

    url = @options[:feed_url]

    domain = URI.parse(url).try(:host) || "Unknown"
    regex = Regexp.union(@query.split(",").map(&:strip).map{|re| Regexp.new(re, Regexp::IGNORECASE)})
    open(url) do |rss|
      feed = RSS::Parser.parse(rss)
      feed_title = "#{feed.try(:channel).try(:title) || feed.try(:title)}"
      feed.items.each do |result|

        if(result.try(:title).to_s.match(regex) || result.try(:description).to_s.match(regex) || result.try(:content).to_s.match(regex))
          results <<
          {
            :title =>  "#{ActionView::Base.full_sanitizer.sanitize(feed_title.to_s)}: #{ActionView::Base.full_sanitizer.sanitize(result.title.to_s)}",
            :url => result.try(:link).try(:href) || result.try(:link).to_s,
            :domain => domain
          }
        end
      end


    end



    return results
  end
end
