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


class ResultFlag < ActiveRecord::Base
  belongs_to :flag
  belongs_to :result
  acts_as_workflowable

  after_validation :set_workflow
  validates :result_id, uniqueness: { scope: :flag_id  }

  def set_workflow
    if(self.workflow_id.blank?)
      self.workflow_id = self.flag.workflow_id
    end
  end
end
