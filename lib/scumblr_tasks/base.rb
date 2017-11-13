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

module ScumblrTask
  class TaskException < StandardError
    def initialize(data)
      super
      @data = data
    end
  end

  class Base
    def self.task_type_name
      nil
    end

    def start
      Thread.current["sidekiq_job_id"] = nil
      # Thread.current["current_task"] = nil
      begin
        run
      rescue=>e
        create_error(e)
        return nil
      end
    end

    def self.task_category
      nil
    end

    def self.options
      return {:sidekiq_worker_queue => {name: "Sidekiq Worker Queue",
                                         description: "Which Sidekiq queue should async workers run in? (Default: worker)",
                                         required: false,
                                         type: :sidekiq_queue

                                         },
               :sidekiq_queue => {name: "Sidekiq Queue",
                                  description: "Which Sidekiq queue should the task run in? (Applies only to parent task, not async workers. Default: async_worker)",
                                  required: false,
                                  type: :sidekiq_queue
                                  },
               }
    end

    def self.config_options
      {}
    end

    def self.description
      ""
    end

    def initialize(options={})
      @return_batched_results = true unless defined?(@return_batched_results)

      @options = options.with_indifferent_access
      thread_tracker = ThreadTracker.new()
      thread_tracker.create_tracking_thread(@options[:_self])
      @event_metadata = {}
      #Thread.current[:current_task] = @options[:_self].id.to_s
      # Setup event hash for storing event types and IDs with tasks
      # Each time the task runs, all event data is moved into the
      # previous events key.
      runtime_options = nil

      if(@options[:_self].present? && @options.try(:[],:_params).try(:[],:_options) && @options[:_self].run_type == "on_demand")
        runtime_options = @options[:_params].delete(:_options)
        @options = @options[:_self].merge_options(runtime_options, @options)
      end

      if(@options[:_self].present?)
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
      else
        # create_event("Task initialized with _self=>nil Options: #{@options.inspect}", "Warn")
      end

      # build out results filter
      @results = nil

      #if there are options for saved_results or saved_events we'll get results
      #if these are blank they'll get all results
      if(@options.key?(:saved_result_filter) || @options.key?(:saved_event_filter))
        get_saved_results
      end


      begin
        self.class.options.select{ |k,v| v[:type] == :tag}.each do |k, v|
          tags = []
          if @options[k].nil?
            next
          end
          @options[k].split(",").each do |tag_name|
            tags << Tag.where(name: tag_name.strip).first_or_create
          end
          @options[k] = tags
        end
      rescue => e
        create_error("Error parsing tag options. Options: #{@options.inspect}")
      end

      config_options = self.class.config_options
      if(config_options.present? && config_options.class == Hash)
        config_options.each do |k,v|
          value = Rails.configuration.try(k)
          if(value.blank? && v[:required] == true)
            create_error("A required configuration setting is not set for #{self.class.task_type_name}. Setting: #{k}")
            raise "A required configuration setting is not set for #{self.class.task_type_name}. Setting: #{k}"
          end

          instance_variable_set("@#{k}",value)
        end
      end
    end

    #gets results based on saved_results_filter or saved_event_filter options
    def get_saved_results
      if(@options[:saved_result_filter].present?)
        filter = SavedFilter.where(saved_filter_type:"Result", id: @options[:saved_result_filter]).try(:first)
        @results = filter.perform_search({}, 1, 25, {include_metadata_column: true, includes:nil})[1].readonly(false)
        #@results = @results.per(@result.total_count)

      end

      if(@results == nil)
        @results = Result
      end

      if(@options[:saved_event_filter].present?)
        filter = SavedFilter.where(saved_filter_type:"Event", id: @options[:saved_event_filter]).try(:first)
        event_results = filter.perform_search({}, 1, 50)[1]
        if event_results.total_count > 50
          event_results = event_results.per(event_results.total_count)
        end
        if(event_results)
          ids = event_results.select{|r| r.eventable_type == "Result"}.map(&:eventable_id)
          @results = @results.where(id: ids)
        end
      end

      if(@results == Result)
        @results = Result.all
      end

      if @results.respond_to?(:total_count)
        @total_result_count = @results.total_count
      else
        @total_result_count = @results.count
      end

      if(@return_batched_results != false)
        @results = @results.find_each(batch_size: 10)
      end

    end

    def run

    end


    private

    def update_sidekiq_status(message, num=nil, total=nil)
      status_updates = {submessage: "#{message}"}
      status_updates.merge!({at: num.to_i}) if num
      status_updates.merge!({total: total.to_i}) if total
      if(@options.try(:[],:_params).try(:[],:_jid).present?)
        Sidekiq::Status.broadcast(@options[:_params][:_jid], status_updates)
      end
    end

    def create_event(event, level="Error")
      if(event.respond_to?(:message))
        details = "An error occurred in #{self.class.task_type_name}. Error: #{event.try(:message)}\n\n#{event.try(:backtrace)}"
      else
        details = event.to_s
      end

      if(level == "Error")
        Rails.logger.error details
      elsif(level == "Warn") or (level == "Warning")
        Rails.logger.warn details
      else
        Rails.logger.debug details
      end

      event_details = Event.create(action: level, eventable_id: @options.try(:[],:_self).try(:id), eventable_type: "Task", source: "Task: #{self.class.task_type_name}", details: details)

      @event_metadata[level] ||= []
      @event_metadata[level] << event_details.id
      if(Thread.current[:current_task])
        #create an event linking the updated/new result to the task
        Thread.current["current_events"] ||={}
        Thread.current["current_events"].merge!(@event_metadata)
      elsif(Thread.current["sidekiq_job_id"].present?)
        Sidekiq.redis do |redis|
          redis.sadd("#{Thread.current["sidekiq_job_id"]}:events:#{level}",event_details.id)
        end
      end
    end

    def create_error(event)
      create_event(event, "Error")
    end

    # Adds an entry to the trends key in the task's metadata
    # Expects a key (which will be created or added to) and a hash
    # containing a list of key/values pairs t
    def save_trends(time_value=Time.now)
      if defined? @trends && @trends.count > 0 && @options[:_self].present?
        @trend_options ||= {}
        @options[:_self].metadata ||={}
        @options[:_self].metadata["trends"] ||={}
        @trends.each do |key, counts|
          @options[:_self].metadata["trends"][key] ||= {"data"=>[]}
          if @trend_options[key].try(:[],"chart_options").present?
            @options[:_self].metadata["trends"][key]["library"] = @trend_options[key]["chart_options"]
          end

          if(@trend_options[key].try(:[],"options").try(:[],"date_format").present?)
            date_value = time_value.strftime(@trend_options[key].try(:[],"options").try(:[],"date_format"))
          else
            date_value = time_value.strftime("%b %d %Y %H:%M:%S")
          end

          counts.each do |trend_name, trend_value|
            series = @options[:_self].metadata["trends"][key]["data"].select{|el| el["name"] == trend_name }.first

            if(series.blank?)



              series = {"name"=> trend_name, "data" =>{ date_value => trend_value}}
              if defined?(@trend_options) && @trend_options.try(:[],key).try(:[],"series_options").try(:[],trend_name)
                series["library"] = @trend_options[key]["series_options"][trend_name]
              end

              @options[:_self].metadata["trends"][key]["data"] << series
            else
              series["data"][date_value] = trend_value
            end
          end

        end
      end
    end
  end
end
