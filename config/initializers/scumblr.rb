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


Scumblr::Application.configure do
  # Should Scumblr automatically generate screenshots for new results
  config.sketchy_url = "http://localhost:8000/api/v1.0/capture"
  config.sketchy_use_ssl = false  # Does sketchy use ssl?
  # config.sketchy_verify_ssl = true # Should scumblr verify sketchy's cert
  config.sketchy_tag_status_code = true # Add a tag indicating last status code sketchy received
  # config.sketchy_access_token = "" # Access token for sketchy

  # Provider configurations

  config.ebay_access_key = 'AmanDiwa-testapp-PRD-c38c4f481-2bca775a'

  config.facebook_app_id = '1696025693988631'
  config.facebook_app_secret = '8c0e989fa1a7be5a7e30b574ff98d3f4'

  #config.google_developer_key = ''
  #config.google_cx  = ''
  #config.google_application_name = ''
  #config.google_application_version = ''

  #config.youtube_developer_key = ''
  #config.youtube_application_name = ''
  #config.youtube_application_version = ''

  config.twitter_consumer_key        = 'zOPpt0neFIuD3dEr6mRUm5cwS'
  config.twitter_consumer_secret     = '0nbkU5CNYyouuf5pkzN0vufTkTls8K7hGx7fu97WmsTzE1DcJp'
  config.twitter_access_token        = '4890900389-ZzDO5x1xxi7lo3n5WKUmXbasKfqHEpMDz8xQanv'
  config.twitter_access_token_secret = '6TJGwt2ikgIo3lELJhC0Kzut3CvGra5o60o8l4l0ksfKz'


end
