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
require 'sidekiq-limit_fetch'
require 'sidekiq-scheduler/web'



Sidekiq::BasicFetch.class_eval do
  # We do not want jobs to be pushed back onto the queue if sidekiq is terminated.
  def self.bulk_requeue(inprogress, options)
    return
  end

end

Sidekiq.configure_client do |config|
  # If user has specified a redis connection string, use it
  config.redis = { url: Rails.configuration.try(:redis_connection_string), network_timeout: 3, size:15 } if Rails.configuration.try(:redis_connection_string) 
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 1.days
  end
end

Sidekiq.configure_server do |config|
  # If user has specified a redis connection string, use it
  config.redis = { url: Rails.configuration.try(:redis_connection_string), network_timeout: 3 } if Rails.configuration.try(:redis_connection_string)

  # Setup sidekiq queues.
  # If a user has specified command line queues, use those
  # otherwise if use has queues in config file, use those
  # default to async_worker, worker, and runner queues

  if(config.options[:queues] == ["default"])
    if(ENV["SIDEKIQ_QUEUES"].present?)
      config.options[:queues] = ENV["SIDEKIQ_QUEUES"].split(",")
    elsif(Rails.configuration.try(:sidekiq_queues))
      config.options[:queues] = Rails.configuration.try(:sidekiq_queues)
    else
      config.options[:queues] = ["async_worker", "worker", "runner", "default"]
    end
  end

  # Prevent runners and workers from taking all the workers
  Sidekiq::Queue['runner'].process_limit = 5
  Sidekiq::Queue['worker'].process_limit = 10

  Rails.logger = Sidekiq::Logging.logger
  ActiveRecord::Base.logger = Sidekiq::Logging.logger
  Sidekiq::Logging.logger.level = Logger::INFO

  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 1.days
  end
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 1.days
  end
  # Sidekiq::Client.reliable_push! if !Rails.env.test? && Sidekiq::Client.respond_to?(:reliable_push!)
end

# Add a broadcast method that can be used to update the current status of running tasks
# from outside the task
module Sidekiq::Status
  class << self
    def broadcast jid, status_updates
        Sidekiq.redis do |conn|
          conn.multi do
            conn.hmset  "sidekiq:status:#{jid}", 'update_time', Time.now.to_i, *(status_updates.to_a.flatten(1))
            conn.expire "sidekiq:status:#{jid}", 1.day.to_i
            conn.publish "status_updates", jid
          end[0]
        end
    end
  end
end

Task.update_schedules if Task.new.respond_to?(:frequency)
