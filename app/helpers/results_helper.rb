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
#require 'aws-sdk'

module ResultsHelper

  def get_result_attachment_expiring_url(id)
    ResultAttachment.find(id).get_expiring_url
  end

  def make_link(result)
    if result.metadata.try(:[], "sketchy_response").present?
      url = URI(result.metadata["sketchy_response"])
      parsed_url = url.path.match(/\/([^\/]+)\/(.+)/)
      aws_resource = AWS::S3.new({:s3_endpoint=>"s3.amazonaws.com", :region=>"us-west-1"})
      obj = aws_resource.buckets[parsed_url[1]].objects[parsed_url[2]] # no request made
      return obj.url_for(:read, :expires => 10*60)
    end
  end
end
