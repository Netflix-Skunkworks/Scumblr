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


class Status < ActiveRecord::Base
  #attr_accessible :name
  has_many :results
  after_save :reset_default

  def reset_default

    if(self.default == true)
      default_status = Status.find_all_by_default(true)
      default_status.each do |status|
        status.update_attributes(:default=>false) if status != self
      end
 
      self.results << Result.find_all_by_status_id(nil)
    end
  end

  def to_s
    name
  end
end
