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


class ScreenshotRunner
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(result_id)

    Sidekiq.logger.warn "*Result id: #{result_id.inspect}"
    total 100
    at 0, "t:Preparing to generate"
    result_ids = Array(result_id.blank? ? Result.all.map{|r| r.id} : result_id)
    count = 0
    total_tasks = result_ids.count
    total total_tasks
    result_ids.each do |id|


      begin
        Sidekiq.logger.warn "**Generating: #{id.inspect}"
        @result = Result.find(id)
        at count, "t:Generating: #{@result.title}"
        @result.create_attachment_from_sketchy(@result.url)
      rescue StandardError=>e
        Sidekiq.logger.error "#{e.message}"
      end
      count += 1
    end
  end

end
