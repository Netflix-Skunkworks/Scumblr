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

class SearchProvider::Twitter < SearchProvider::Provider
  def self.provider_name
    "Twitter Search"
  end

  def self.options
    {
      :results=>{name: "Max results", description: "Specify the number of results to retrieve", required: false},
      :from=>{name: "Search specific user", description: "Search a specific user for tweets", required: false}
    }
  end


  def self.description
    "Search Twitter for matching Tweets and create results"
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
    @options.reverse_merge!({:result_type=>"recent", :from=>"", :results=>100})
    @options[:results] = Integer(@options[:results])


  end

  def run



    client = Twitter::REST::Client.new do |config|
      config.consumer_key    = @twitter_consumer_key
      config.consumer_secret   = @twitter_consumer_secret
      config.access_token    = @twitter_access_token
      config.access_token_secret = @twitter_access_token_secret
    end
    begin
      search_results = client.search(@query, :result_type => "recent", :from => @options[:from])
      results = search_results.take(@options[:results]).map do |tweet|
        { :title => encode(tweet.try(:user).try(:screen_name).to_s + ": " + tweet.text.to_s), :url => encode(tweet.url.to_s), :domain => "twitter.com"}
        #{ :user => tweet.user.screen_name, :created => tweet.created_at, :url => tweet.url.to_s, :text => tweet.text}
      end

      return results
    rescue StandardError=>e
      Rails.logger.error "Error: " + e.message + " " + e.backtrace.inspect
      []
    end
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
