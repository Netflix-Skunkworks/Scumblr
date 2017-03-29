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

class SystemMetadata < ActiveRecord::Base
  validates :key, uniqueness: true
  validates :key, presence: true
  validates :metadata, :presence => { :message => "bad json" }
  # set custom emtadata presence message and check if nil using prescence
  attr_accessor :metadata_raw

  def metadata_raw
    self.metadata.to_s
  end

  def metadata_raw=(value)
    begin
      self.metadata = JSON(value)

    rescue
      self.metadata = ""
    end
  end
  # validates :start, :end, :values, :presence => true
end
