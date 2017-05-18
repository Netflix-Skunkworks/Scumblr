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
      aws_client = Aws::S3::Client.new(region: "us-east-1")
      signer = Aws::S3::Presigner.new(client: aws_client)
      return signer.presigned_url(:get_object, bucket: parsed_url[1], key: parsed_url[2], expires_in: 10*60)
      #return obj.url_for(:read, :expires => 10*60)
    end
  end
end
