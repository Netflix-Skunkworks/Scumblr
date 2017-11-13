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


class ScumblrTask::ResultMaintenance < ScumblrTask::Async
  def self.task_type_name
    "Result Maintenance"
  end

  def self.task_category
    "Maintenance"
  end

  def self.options
    return super
  end

  def self.description
    "Creates a metadata key on all results to expose the add vulnerability functionality"
  end

  def initialize(options={})
    # Do setup
    super

  end

  def perform_work(r)
    if r.metadata["vulnerabilities"].nil?
      r.update_vulnerabilities()
    end
  end

  def run
    super
  end
end
