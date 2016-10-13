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


# gem install twitter
require 'twitter'

class SearchProvider::TwitterUser < SearchProvider::Provider
  def self.provider_name
    "Twitter User Search"
  end

  def self.options
    {
      :results=>{name: "Max results", description: "Specify the number of results to retrieve", required: false},
      :search_username_only => { name: "Search username only",
        description: "Search for query term in username only (not in description field)",
        required: false,
        type: :boolean,
        default: false
      }  
    }
  end

  def self.description
    "Search Twitter for matching Users and create results"
  end

  def self.config_options
    {:twitter_consumer_key =>{ name: "Twitter Consumer Key",
      description: "Along with other values provides access to the twitter API",
      required: true
      },
      :twitter_consumer_secret =>{ name: "Twitter Consumer Secret",
      description: "Along with other values provides access to the twitter API",
      required: true
      },
      :twitter_access_token =>{ name: "Twitter Access Token",
      description: "Along with other values provides access to the twitter API",
      required: true
      },
      :twitter_access_token_secret =>{ name: "Twitter Access Token Secret",
      description: "Along with other values provides access to the twitter API",
      required: true
      }
    }
  end

  def initialize(query, options={})
    super

    #Delete blank options (since Rails will save blank string if the option is not specified)
    @options.delete_if {|k, v| v.blank? }
    @options.reverse_merge!({"results" =>100})
    @options["results"] = Integer(@options["results"])


  end

  def run
    


    client = Twitter::REST::Client.new do |config|
      config.consumer_key    = @twitter_consumer_key
      config.consumer_secret   = @twitter_consumer_secret
      config.access_token    = @twitter_access_token
      config.access_token_secret = @twitter_access_token_secret
    end
    
    
      previous_results = nil
      page=1
      max_pages=51
      search_results = []

      
      while(search_results.count < @options["results"] && page <= max_pages)
        Rails.logger.debug "Searching page #{page}"
        temp_results_count = 0
        begin
          attempts=1
          max_attempts=3
          temp_results = client.user_search(@query, {page: page, count: 20})

          temp_results_count = temp_results.count
        rescue Twitter::Error::TooManyRequests => e
          if(attempts > max_attempts)
            Rails.logger.error "Max attempts reached. Moving to next page"
            next
          end
          Rails.logger.warn "Rate limit exceeded. Waiting #{e.rate_limit.reset_in} seconds (Attempt #{attempts})"
          attempts += 1
          
          sleep e.rate_limit.reset_in
          retry
          
        rescue StandardError=>e
          Rails.logger.error "Error: " + e.message + " " + e.backtrace.inspect
          temp_results = []
        end
        temp_results.delete_if{|x| !x.screen_name.downcase.include?(@query.downcase)} if (@options["search_username_only"] == true || @options["search_username_only"] == "1")
        search_results += temp_results
        search_results.uniq!
        page += 1

        # If this page returned no results or the results as the same as the last page. This is needed due to a bug in the
        # twitter api
        if(temp_results_count < 1)
          Rails.logger.debug "Quitting: No results"
          break
        elsif(temp_results == previous_results) 
          Rails.logger.debug "Quitting: Duplicate results"
        end
        previous_results = temp_results

      end
      


      results = search_results.take(@options["results"]).map do |user|

        { :url => encode(user.url.to_s), :title => "Twitter: @#{user.screen_name}", :domain => "twitter.com", :metadata=>{twitter_user_description: encode(user.description.to_s)}} 

      end
      Rails.logger.debug "Done."

      return results[0..@options["results"]-1]
  end

  private

  def encode(string)
    encoding_options = {
      :invalid       => :replace,  # Replace invalid byte sequences
      :undef       => :replace,  # Replace anything not defined in ASCII
      :replace       => '',    # Use a blank for those replacements
      :universal_newline => true     # Always break lines with \n
    }

    string.encode(Encoding.find("ASCII"), encoding_options)
  end

end
