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


class ResultAttachment < ActiveRecord::Base
  attr_reader :attachment_remote_url
  belongs_to :result
  has_attached_file :attachment, :styles => lambda{ |a| a.content_type.match(/\Aimage\/.*\Z/) ? { :medium => "300x300>", :thumb => "100x100>" } : {}} ,:default_url => "/images/:style/missing.png", adapter_options: { hash_digest: Digest::SHA256 }
  validates_attachment_content_type :attachment , :content_type => /\Aimage\/.*\Z|\Atext\/plain\Z/

  
  def attachment_remote_url=(url_value)
    self.attachment = URI.parse(url_value)
    @attachment_remote_url = url_value
  end


  def get_expiring_url
    self.attachment.try(:expiring_url, 3600)
  end

  def pretty_filesize
    Filesize.from(self.try(:attachment).try(:size).to_s + "b").pretty
  end



end
