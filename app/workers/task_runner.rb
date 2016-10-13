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



class TaskRunner
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(task_ids=nil)
    
    at 0, "A:Preparing to run tasks"
    task_groups = Array(task_ids.blank? ? Task.where(enabled:true).group_by(&:group).sort : Task.where(id: task_ids).group_by(&:group).sort)
    count = 0
    total_count = task_groups.map{|k,v| v.count}.sum
    total total_count

    task_groups.each do |group, tasks|
      Rails.logger.warn "Running group #{group}"
      at count, "A:Running group #{group}"

      workers = []
      tasks.each do |t|
        Rails.logger.warn "Running #{t.name}"
        at count, "A:Running: #{t.name}"
        workers << TaskWorker.perform_async(t.id)
      end

      while(!workers.empty?)
        at count, "A:#{workers.count}/#{total_count} tasks complete"
        Rails.logger.warn "#{workers.count} tasks remaining"
        workers.delete_if do |worker_id|
          status = Sidekiq::Status::status(worker_id)
          Rails.logger.warn "Task #{worker_id} #{status}"
          status == :complete && count += 1
        end
      
        sleep(0.2)
      end
    end
 
  end

end

