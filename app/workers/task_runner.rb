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

require 'sidekiq-scheduler'
require 'sidekiq-status'

class TaskRunner
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :queue => :runner, :retry => 0, :backtrace => true 

  def perform(task_ids=nil, task_params=nil, task_options=nil)
    begin
      at 0, "A:Preparing to run tasks"
      task_groups = Array(task_ids.blank? ? Task.where(enabled:true, run_type:"scheduled").group_by(&:group).sort : Task.where(id: task_ids).group_by(&:group).sort)
      count = 0
      total_count = task_groups.map{|k,v| v.count}.sum
      total total_count
      group_index = 1
      task_groups.each do |group, tasks|
        Rails.logger.warn "Running group #{group}"
        at count, "A:Running group #{group}/#{task_groups.count}"

        workers = []
        tasks.each do |t|
          Rails.logger.warn "Running #{t.name}"
          # at count, "A:Queuing: #{t.name}"
          if(t.options.try(:[], :sidekiq_queue).present?)
            queue_name = t.options[:sidekiq_queue]
            if(Sidekiq::ProcessSet.new.map{|q| q["queues"]}.flatten.uniq.include?(queue_name))
              workers << TaskWorker.set(:queue => queue_name.to_sym).perform_async(t.id, task_params, task_options)
            else
              msg = "Fatal error in TaskRunner. Could not run #{t.id} in queue #{queue_name}. Queue not found."
              Event.create(action: "Fatal", eventable: t, source: "TaskRunner", details: msg)
            end
          else
            workers << TaskWorker.perform_async(t.id, task_params, task_options)
          end
          
        end

        while(!workers.empty?)
          at count, "A:Running group #{group_index}/#{task_groups.count}. Tasks complete: #{count}/#{total_count}."
          
          Rails.logger.warn "#{workers.count} tasks remaining"
          workers.delete_if do |worker_id|
            status = Sidekiq::Status::status(worker_id)
            Rails.logger.warn "Task #{worker_id} #{status}"
            (status != :queued && status != :working) && count += 1
          end
        
          sleep(2)
        end
        group_index += 1
      end
    rescue=>e
      msg = "Fatal error in TaskRunner. Task ids#{task_ids}. Task params:#{task_params}. Exception: #{e.message}\r\n#{e.backtrace}"
      Event.create(action: "Fatal", source: "TaskRunner", details: msg)
      Rails.logger.error msg
    end
 
  end

end

