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

class SearchProvider::Facebook < SearchProvider::Provider
  def self.provider_name
    "Facebook Search"
  end

  def self.options
    {}
  end

  def initialize(query, options={})
    super
    app_id = Rails.configuration.try(:facebook_app_id)
    app_secret = Rails.configuration.try(:facebook_app_secret)
    oauth = Koala::Facebook::OAuth.new(app_id, app_secret)
    @access_token = oauth.get_app_access_token
  end

  def run

    if(@access_token.blank?)
      Rails.logger.error "Unable to search Facebook. No access token. Please define an app id and app secret as facebook_app_id and facebook_app_secret in the Scumblr initializer."
      return
    end


    @graph = Koala::Facebook::API.new(@access_token)
    search_results = @graph.search(@query).map do |result|
      {   :post_id => 'https://www.facebook.com/' + result['id'].to_s.gsub!(/_/, '/posts/'),
        :user_id => result['from']['id'],
        :published => result['created_time'].to_s,
        :caption => (result['caption'] || ""),
        :message => (result['message'] || ""),
        :parsed_uri => (result['message'].nil? ? "" : URI.extract(result['message'], ['http', 'https']).join(' '))
        }
    end

    search_results.map{|result| {title: (result[:message].empty? ? encode(result[:caption]) : encode(result[:message])).truncate(128),
                   url: result[:post_id], domain: "facebook.com"}}
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
