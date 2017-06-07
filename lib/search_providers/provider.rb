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


module SearchProvider
  class Provider
    def self.provider_name
      nil
    end

    def self.options
      return {}
    end

    def initialize(query , options={})

      config_options = self.class.config_options
      if(config_options.present? && config_options.class == Hash)
        config_options.each do |k,v|
          value = Rails.configuration.try(k)
          if(value.blank? && v[:required] == true)
            create_error("A required configuration setting is not set for #{self.class.provider_name}. Setting: #{k}")
            raise "A required configuration setting is not set for #{self.class.provider_name}. Setting: #{k}"
          end

          instance_variable_set("@#{k}",value)
        end
      end

      @query = query
      @options = options
      @options[:_self].metadata ||={}

      if @options[:_self].metadata["current_events"].present?
        @options[:_self].metadata["previous_events"] = @options[:_self].metadata["current_events"]
        @options[:_self].metadata["current_events"] = {}
      end
      # Setup event hash for storing CRUD operations with results
      # Each time the task runs, all result data is moved into the
      # previous results key.

      if @options[:_self].metadata["current_results"].present?
        @options[:_self].metadata["previous_results"] = @options[:_self].metadata["current_results"]
        @options[:_self].metadata["current_results"] = {}

      end
      @options[:_self].save
      @event_metadata = {}
      thread_tracker = ThreadTracker.new()
      thread_tracker.create_tracking_thread(@options[:_self])
    end

    def self.config_options
      {}
    end

    def self.description
      ""
    end

    def run

    end

    def start
      Thread.current["sidekiq_job_id"].present?
      Thread.current["current_task"].present?
      run
    end

    private

    def create_error(event)
      create_event(event, "Error")
    end

    def create_event(event, level="Error")
      if(event.respond_to?(:message))
        details = "An error occurred in #{self.class.provider_name}. Error: #{event.try(:message)}\n\n#{event.try(:backtrace)}"
      else
        details = "An error occurred in #{self.class.provider_name}. Error #{event.to_s}"
      end

      if(level == "Error")
        Rails.logger.error details
      elsif(level == "Warn") or (level == "Warning")
        Rails.logger.warn details
      else
        Rails.logger.debug details
      end
      puts level

      event_details = Event.create(action: level, eventable_type: "Task", source: "Task: #{self.class.provider_name}", details: details)

      @event_metadata[level] ||= []
      @event_metadata[level] << event_details.id
      if(Thread.current[:current_task])
        #create an event linking the updated/new result to the task
        Thread.current["current_events"] ||={}
        Thread.current["current_events"].merge!(@event_metadata)
      end

      # @options[:_self].metadata.merge!(Thread.current["current_events"])
      # @options[:_self].save
      # Thread.current["current_results"] = {}
      # Thread.current["previous_results"] = {}
      # Thread.current["current_events"] = {}
      # Thread.current["previous_events"] = {}
    end
  end

end
