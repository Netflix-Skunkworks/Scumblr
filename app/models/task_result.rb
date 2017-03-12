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


class TaskResult < ActiveRecord::Base
  belongs_to :result
  belongs_to :task

  validates :result_id, uniqueness: { scope: :task_id }

  delegate :task_type, to: :task, allow_nil: true
  delegate :query, to: :task, allow_nil: true

  def task_name
    self.try(:task).try(:name) || "<Task Deleted>"
  end

end
