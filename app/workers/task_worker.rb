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
  sidekiq_options :queue => :worker, :retry => 0, :backtrace => true

  def perform(task_id, task_params=nil, task_options=nil)
    t= Time.now

    if(task_params.present?)
      task_params = {:_body=> task_params}
    else
      task_params = {}
    end

    if(task_options.present?)
      task_params.merge!(:_options=>task_options)
    end

    begin
      @task = Task.find(task_id)

      task_params.merge!(:_jid=>@jid)
      
      if(@task)
        @task.events << Event.create(field: "Task", action: "Run", source: "Task Worker")
        at 0, "B:Running #{@task.name}"
        @task.perform_task(task_params)
      else
        Event.create(action: "Error", source:"Task: #{@task.id}", details: "Unable to run task with id: #{task_id}. No such task.", eventable_type: "Task", eventable_id: task_id)
      end

    rescue Exception=>e
      msg = "Fatal low level exception in TaskWorker. Task id#{task_id}. Task params:#{task_params}. Exception: #{e.message}\r\n#{e.backtrace}"
      Event.create(action: "Fatal", source: "TaskWorker", details: msg,eventable_type: "Task", eventable_id: task_id)
      return
    rescue StandardError=>e
      msg = "Fatal error in TaskWorker. Task id#{task_id}. Task params:#{task_params}. Exception: #{e.message}\r\n#{e.backtrace}"
      Event.create(action: "Fatal", source: "TaskWorker", details: msg,eventable_type: "Task", eventable_id: task_id)
      Rails.logger.error msg
      return
    end

  end
end
