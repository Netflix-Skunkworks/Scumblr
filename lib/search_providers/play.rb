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
require 'market_bot'

class SearchProvider::Play < SearchProvider::Provider
  def self.provider_name
    "Google Play Search"
  end

  def self.options
    {
      :require_all_terms=>{name: "Require all terms", description: "If set to \"true\" will ensure all search terms are contained in result", required: false},
    }
  end

  def initialize(query, options={})
    super
    @hydra = Typhoeus::Hydra.new(:max_concurrency => 5)
    @options.delete_if {|k, v| v.blank? }
    @options.reverse_merge!({:require_all_terms=>"false"})

  end

  def run
    sq = MarketBot::Android::SearchQuery.new(@query, :hydra => @hydra)
    sq.update
    results = []
    sq.results.each do |result|
      skip_result = false
      if(@options[:require_all_terms] == "true")
        @query.split(" ").each do |term|
          if !result.to_s.match(term)
            skip_result = true
            break
          end
        end
      end

      next if skip_result

      results <<  {   :title => result[:title],
              :url => result[:market_url],
              :domain => 'play.google.com'
              }
    end

    return results
  end

  private
end
