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
require 'rss'

class SearchProvider::CT < SearchProvider::Provider
  def self.provider_name
    "Certificate Transparency"
  end

  def self.options
    {
      :serials =>{name: "Serials to ignore", description: "Serial numbers to ignore from results (e.g false positives)", required: false}
    }
  end

  def initialize(query, options={})
    super
    #Delete blank options (since Rails will save blank string if the option is not specified)
  end

  def run

    results = []

    url = "https://api.ctwatch.net/domain/" + @query

    domain = URI.parse(url).try(:host) || "Unknown"
    regex = Regexp.union(@options[:serials].to_s.split(",").map(&:strip).map{|re| Regexp.new(re, Regexp::IGNORECASE)})
    open(url) do |rss|
      feed = RSS::Parser.parse(rss, do_validate=false, ignore_unknown_element=true)
      feed_title = "#{feed.try(:channel).try(:title) || feed.try(:title)}"
      feed.items.each do |result|
        if(!result.try(:title).to_s.match(regex))
          results <<
          {
            :title =>  "#{ActionView::Base.full_sanitizer.sanitize(feed_title.to_s)}: #{ActionView::Base.full_sanitizer.sanitize(result.title.to_s)}",
            :url => result.try(:link).try(:href) || result.try(:link).to_s,
          }
        end
      end
    end

    return results
  end
end
