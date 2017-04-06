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


require 'sidekiq'
require 'sidekiq-status'

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware
  end
end

Sidekiq.configure_server do |config|

  Rails.logger = Sidekiq::Logging.logger
  ActiveRecord::Base.logger = Sidekiq::Logging.logger
  Sidekiq::Logging.logger.level = Logger::INFO

  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 1.days # default
  end
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware
  end
end

module Sidekiq::Status
  class << self
    def broadcast jid, status_updates
        Sidekiq.redis do |conn|
          conn.multi do
            conn.hmset  "sidekiq:status:#{jid}", 'update_time', Time.now.to_i, *(status_updates.to_a.flatten(1))
            conn.expire "sidekiq:status:#{jid}", Sidekiq::Status::DEFAULT_EXPIRY
            conn.publish "status_updates", jid
          end[0]
        end
    end
  end
end