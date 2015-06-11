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



class SearchTask
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(search_id)

      begin
        Rails.logger.warn "Search Tasking... #{search_id}"
        @search = Search.find(search_id)
        at 0, "B:Running #{@search.name}"
        @search.perform_search
      rescue StandardError=>e
        Rails.logger.error "#{e.message}"
      end
  end
end



