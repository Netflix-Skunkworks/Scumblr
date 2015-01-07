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


class ScreenshotSyncTaskRunner
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(result_id)
    queue_size = 1
    total 100
    at 0, "s:Preparing to sync"
    result_ids = Array(result_id)

    Sidekiq.logger.warn "Running Sync Task For: #{result_id}"

    completed = 0
    total_tasks = result_ids.count
    job_ids = []
    total total_tasks
    at completed, "s:Syncing Screenshots (#{completed}/#{total_tasks})"
    while(completed < total_tasks)
      while(job_ids.count < queue_size && result_ids.count > 0)
        job_ids << ScreenshotRunner.perform_async(result_ids.pop)
      end


      job_ids.each do |j|
        status = Sidekiq::Status::status(j)
        if(status == :complete ||
           status == :failed ||
           status == nil)
          job_ids.delete(j)
          completed += 1
        end
      end

      at completed, "s:Syncing Screenshots (#{completed}/#{total_tasks})"

    end



  end

end
