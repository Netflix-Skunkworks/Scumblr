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


class ScumblrTask::EventCleaner < ScumblrTask::Base
  def self.task_type_name
    "Event Cleaner"
  end

  def self.task_category
    "Maintenance"
  end

  def self.options
    return super.merge({
      :days_to_keep => {name: "Days to keep",
        description: "Delete all events older than n days.",
        required: false,
        type: :text
      }
    })
  end

  def self.description
    "Delete events not associated with a user id and older than the given number of days."
  end

  def initialize(options={})
    # Do setup
    super

    begin
      @days_to_keep = Integer(@options["days_to_keep"])
    rescue
      @days_to_keep = 7
    end
  end

  def run

    Event.where(user_id:nil).where('created_at < ?', Date.today - @days_to_keep).delete_all
    return []

  end
end
