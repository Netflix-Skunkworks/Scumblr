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


# ScumblrTask class for automatic multithreading
# To use: Inherit this class, define a "perform_work" function that
# accepts one argument (the object to operate on) and define @results
# which is a list of objects to perform_work on. Optionally define
# @workers to be the number of worker threads
class ScumblrTask::AsyncSidekiq < ScumblrTask::Base
  
  def initialize(options)
    @return_batched_results = false
    super(options)

    # Remove Thread.current tracking
    Thread.current[:current_task] = nil
    Thread.current["current_results"] = nil
    Thread.current["current_events"] = nil

  end

  def run
    @trends = []
    @_jid = @options.try(:[],"_params").try(:[],"_jid")
    if(!self.class.respond_to? :worker_class)
      msg = "Incorrectly implemented Async Sidekiq Task. No \"worker_class\" method defined. #{self.inspect}"
      Rails.logger.error msg
      create_error(msg)
      return
    end

    if(!self.class.worker_class.method_defined?(:perform_work))
      msg = "Incorrectly implemented Async Sidekiq Task. No \"perform_work\" method defined. #{self.inspect}"
      Rails.logger.error msg
      create_error(msg)
      return
    end

    # Default to empty array of results to iterate
    @results ||= Result.none

    i = 1

    @workers = []
    _self = @options[:_self]
    @options[:_self] = @options[:_self].id

    # Store @options in redis once to be reused by all tasks
    Sidekiq.redis do |r|
      r.set "#{@_jid}:options", @options.to_json
    end

    
      
    begin
      queue = nil
      if(@options[:sidekiq_worker_queue].present?)
        queue = @options[:sidekiq_worker_queue] 
      else
        queue = :async_worker
      end
      limit = 10000
      if(!Sidekiq::ProcessSet.new.map{|q| q["queues"]}.flatten.uniq.include?(queue.to_s))
        msg = "Fatal error in task #{@options[:_self]}. Queue (#{queue}) not found."
        create_error(msg)
        return
      end



      @results.reorder('').limit(nil).pluck(:id).each_slice(limit).each do |group|
        @workers += Sidekiq::Client.push_bulk("queue"=> queue, "class"=>self.class.worker_class, "args"=>group.map{|rid| [rid, @_jid]})
      end

      # @results.reorder('').limit(nil).pluck(:id).each do |r|
      #   @workers << self.class.worker_class.set(:queue => queue).perform_async(r, @_jid)
      # end
    rescue=>e
      create_error(e)
    end

    # Update job status as tasks are completed
    @completed_count = 0
    while(!@workers.empty?)
      update_sidekiq_status("Processing #{@total_result_count} results.  (#{@completed_count}/#{@total_result_count} completed)", @completed_count, @total_result_count)
      @workers.delete_if do |worker_id|
        status = Sidekiq::Status::status(worker_id)

        # Next statement determines whether to delete the worker from the array. We deleted the worker
        # if the status is not queued or working. In this case we also increment the count by one and
        # try to delete the status in redis.
        (status != :queued && status != :working) && (@completed_count += 1) && (Sidekiq.redis{|r| r.del("sidekiq:status:#{worker_id}")} || true)
      end

      sleep(1)
      
    end

    @options[:_self] = _self

    _self.metadata["current_events"] ||= {}
    _self.metadata["current_results"] ||= {}
    
    if(@_jid)
      Sidekiq.redis do |r|
        _self.metadata["current_events"]["Error"] = r.smembers("#{@_jid}:events:errors").to_a
        _self.metadata["current_events"]["Warning"] = r.smembers("#{@_jid}:events:warnings").to_a
        _self.metadata["current_results"]["updated"] = r.smembers("#{@_jid}:results:updated").to_a
        _self.metadata["current_results"]["created"] = r.smembers("#{@_jid}:results:created").to_a
        r.del "#{@_jid}:events:errors", 
              "#{@_jid}:events:warnings", 
              "#{@_jid}:results:updated", 
              "#{@_jid}:results:created",
              "#{@_jid}:options"
      end
    end

    save_trends
    
    return []
  end

  # Adds an entry to the trends key in the task's metadata
  # Expects a key (which will be created or added to) and a hash
  # containing a list of key/values pairs t
  def save_trends(time_value=Time.now)
    if(@trend_keys.blank?)
      return
    end
    if(@_jid.blank?)
      return
    end
    
      # redis.set "@_jid:#{primary_key}:#{k}:value", 0
      # @chart_options[primary_key] = chart_options
      # @series_options[primary_key] = series_options
      # @trend_options[primary_key] = options
      # @trend_keys
    trend_data = {}
    
    @trend_keys.each do |primary_key, sub_keys|
      trend_data[primary_key] = @options[:_self].metadata.try(:[],"trends").try(:[],primary_key) || {"data"=>[]}

      trend_data[primary_key]["library"] = @chart_options[primary_key] || {}

      date_value = @trend_options.try(:[],primary_key).try(:[],"date_format") ?
        time_value.strftime(@trend_options[primary_key]["date_format"]) : time_value.strftime("%b %d %Y %H:%M:%S")

      sub_keys.each do |trend_name|
        series = trend_data[primary_key]["data"].select{|el| el["name"] == trend_name }.first
        trend_value = 0
        Sidekiq.redis do |redis|
          trend_value = redis.get("#{@_jid}:trends:#{primary_key}:#{trend_name}:value")
          redis.del("#{@_jid}:trends:#{primary_key}:#{trend_name}:value")
        end

        if(series.blank?)
          series = {"name"=> trend_name, "data" =>{ date_value => trend_value}}
          if @series_options.try(:[],primary_key).try(:[], trend_name)
            series["library"] = @series_options[primary_key][trend_name]
          end

          trend_data[primary_key]["data"] << series
        else
          series["data"][date_value] = trend_value
        end

      end
      # @options[:_self].metadata["trends"][primary_key] = trend_data
    end
    
    @options[:_self].metadata ||= {}
    @options[:_self].metadata["trends"] ||={}
    @options[:_self].metadata["trends"].merge!(trend_data)


    if(trend_data.try(:[],"open_vulnerability_count").try(:[],"open"))
      @options[:_self].metadata["latest_results_link"] = {text: "#{trend_data.try(:[],"open_vulnerability_count").try(:[],"open").to_i} results", search:"q[metadata_search]=vulnerability_count:task_id:#{@options[:_self].id}>0"}
    end
    

  end

  # Initialize the trend objects to default values
    def initialize_trends(primary_key, sub_keys, chart_options={}, series_options={}, options={})
      @trend_keys ||= {}
      @trend_keys[primary_key] ||= []
      @trend_keys[primary_key] += sub_keys
      @chart_options ||= {}
      @series_options ||= {}
      @trend_options ||={}
      Sidekiq.redis do |redis|
        Array(sub_keys).each do |k|      
          redis.set "#{@_jid}:trends:#{primary_key}:#{k}:value", 0
        end
      end

      @chart_options[primary_key] = chart_options
      @series_options[primary_key] = series_options
      @trend_options[primary_key] = options

    end
end


module ScumblrWorkers
  class AsyncSidekiqWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker
    sidekiq_options :retry => 0, :backtrace => true

    def perform(r, jid)

      @_jid = jid
      @options =""
      begin
        Thread.current["sidekiq_job_id"] = @_jid
        options = nil
        Sidekiq.redis do |redis|
          options = redis.get "#{jid}:options"
        end
        @options = JSON.parse(options).with_indifferent_access
      rescue=>e
        create_error("Error parsing options in #{self.class} from redis, can not continue. Options retrieved: #{options}. Parent_JID: #{jid}. JobID: #{@jid}. Result: #{r}. Error: #{e.message}. Backtrace: #{e.backtrace}")
        return []
      end

      begin
        config_options = self.class.try(:config_options)
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
      rescue=>e
        create_error("Error parsing config options in #{self.class}, can not continue. Parent_JID: #{jid}. JobID: #{@jid}. Result: #{r}. Error: #{e.message}. Backtrace: #{e.backtrace}")
        return []
      end

      begin
        self.perform_work(r)
      rescue Exception=>e
        create_error("An low level error occurred running perform_work in #{self.class} : #{e.message}\r\n#{e.backtrace}")
      rescue=>e
        create_error("An error occurred running perform_work in #{self.class} : #{e.message}\r\n#{e.backtrace}")
      ensure
        # Thread.current["sidekiq_job_id"] = nil
      end
    end

    private



    # This will at take a key and a hash with values and puts these values into the trends hash
    # if the key already exists in the trends hash it will sum the values together
    # example: @trends = {updated: {results: 1, tasks:10}},  key= :updated, count= {results: 5, tasks: 2}
    #   @trends will be updated to {updated: {results: 6, tasks: 12}}
    def update_trends(key, count, chart_options={}, series_options=[], options={})
      if(@_jid.present?)
        Sidekiq.redis do |redis|
          Array(count).each do |k,v|      
            redis.incrbyfloat "#{@_jid}:trends:#{key}:#{k}:value", v
          end
        end
      end
    end
  

    def create_event(event, level="Error")
      if(event.respond_to?(:message))
        details = "An error occurred in #{self.class.to_s}. Error: #{event.try(:message)}\n\n#{event.try(:backtrace)}"
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
      
      eventable_id = nil
      begin
        if(@options.try(:[],:_self).present?)
          eventable_id = @options.try(:[],:_self).class == Fixnum ? @options.try(:[],:_self) : @options.try(:[],:_self).try(:[],:id)
        end
      rescue

      end

      event_details = Event.create(action: level, eventable_id: eventable_id, eventable_type: "Task", source: "Task: #{self.class.to_s}", details: details)

      if(Thread.current["sidekiq_job_id"].present?)
        Sidekiq.redis do |redis|
          redis.sadd("#{Thread.current["sidekiq_job_id"]}:events:#{level}",event_details.id)
        end
      end
    end

    def create_error(event)
      create_event(event, "Error")
    end
  end
end