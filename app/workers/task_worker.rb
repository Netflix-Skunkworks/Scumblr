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



class TaskWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(task_id)
    t= Time.now

    begin
      @task = Task.find(task_id)

      if(@task)
        @task.events << Event.create(field: "Task", action: "Run", source: "Task Worker")
        at 0, "B:Running #{@task.name}"
        @task.perform_task
      else
        Event.create(action: "Error", source:"Task: #{@task.id}", details: "Unable to run task with id: #{task_id}. No such task.", eventable_type: "Task", eventable_id: task_id)
      end

    rescue StandardError=>e
      event = Event.create(action: "Error", source:"Task: #{@task.name}", details: "Unable to run task, investigate: #{@task.name}.\n\nError: #{e.message}\n\n#{e.backtrace}", eventable_type: "Task", eventable_id: @task.id )
      Rails.logger.error "#{e.message}"
    end

  end
end
