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



class SearchRunner
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(search_ids=nil)

    Rails.logger.warn "**Search ids: #{search_ids.inspect}"
    
    at 0, "A:Preparing to sync"
    search_groups = Array(search_ids.blank? ? Search.where(enabled:true).group_by(&:group).sort : Search.where(id: search_ids).group_by(&:group).sort)
    count = 0
    total_count = search_groups.map{|k,v| v.count}.sum
    total total_count

    search_groups.each do |group, searches|
      Rails.logger.warn "Running group #{group}"
      at count, "A:Running group #{group}"

      tasks = []
      searches.each do |s|
        Rails.logger.warn "Running #{s.name}"
        at count, "A:Running: #{s.name}"
        tasks << SearchTask.perform_async(s.id)
      end

      while(!tasks.empty?)
        at count, "A:#{tasks.count}/#{total_count} tasks complete"
        Rails.logger.warn "#{tasks.count} tasks remaining"
        tasks.delete_if do |task_id|
          status = Sidekiq::Status::status(task_id)
          Rails.logger.warn "Task #{task_id} #{status}"
          status == :complete && count += 1
        end
      
        sleep(0.2)
      end
    end
 
  end

end

