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

module SearchProvider
  class Facebook < SearchProvider::Provider
    def self.provider_name
      'Facebook Search'.freeze
    end

    def self.options
      {}
    end

    def initialize(query, options = {})
      super
      app_id = Rails.configuration.try(:facebook_app_id)
      app_secret = Rails.configuration.try(:facebook_app_secret)
      oauth = Koala::Facebook::OAuth.new(app_id, app_secret)
      @access_token = oauth.get_app_access_token
    end

    def run
      if @access_token.blank?
        Rails.logger.error 'Unable to search Facebook. No access token.
                            Please define an app id and app secret as facebook_app_id and facebook_app_secret in the Scumblr initializer.'.freeze
        return
      end

      build_results
    end

    private

    def build_results
      res = []
      graph = Koala::Facebook::API.new(@access_token)
      graph.search(@query, type: 'page'.freeze).map do |result|
        sub_result = graph.get_connection result['id'].to_i, 'feed'.freeze, fields: %w(id created_time caption message)
        next unless sub_result
        res << manage_sub_result(sub_result)
      end
      res.flatten!
    end

    def manage_sub_result(sub_result)
      res = []
      sub_result.each do |sr|
        caption = (sr['caption'] || '').force_encoding(Encoding::UTF_8).freeze
        msg = (sr['message'] || '').force_encoding(Encoding::UTF_8).freeze
        res << {
            title: (msg.empty? ? caption : msg).truncate(128),
            url: "https://www.facebook.com/#{sr['id'].to_s.gsub!(/_/, '/posts/')}",
            domain: 'facebook.com'.freeze
        }
      end
      res
    end
  end
end