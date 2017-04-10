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
  
  def initialize
  end

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

    workers = []
    _self = @options[:_self]
    @options[:_self] = @options[:_self].id
    @results.reorder('').limit(nil).pluck(:id).each do |r|
      if(@options[:sidekiq_queue].present?)
        workers << self.class.worker_class.set(:queue => @options[:sidekiq_queue]).perform_async(r, @options)
      else
        workers << self.class.worker_class.set(:queue => :async_worker).perform_async(r, @options)
      end
    end

    @results = nil
    count = 0
    while(!workers.empty?)
      update_sidekiq_status("Processing #{@total_result_count} results.  (#{count}/#{@total_result_count} completed)", count, @total_result_count)
      
      Rails.logger.warn "#{workers.count} tasks remaining"
      workers.delete_if do |worker_id|
        status = Sidekiq::Status::status(worker_id)
        Rails.logger.warn "Task #{worker_id} #{status}"
        (status != :queued && status != :working) && count += 1
      end
      sleep(1)
    end
    @options[:_self] = _self

    _self.metadata["current_events"] ||= {}
    _self.metadata["current_results"] ||= {}
    _jid = @options.try(:[],"_params").try(:[],"_jid")
    if(_jid)
      Sidekiq.redis do |r|
        _self.metadata["current_events"]["Error"] = r.smembers("#{_jid}:events:errors").to_a
        _self.metadata["current_events"]["Warning"] = r.smembers("#{_jid}:events:warnings").to_a
        _self.metadata["current_results"]["updated"] = r.smembers("#{_jid}:results:updated").to_a
        _self.metadata["current_results"]["created"] = r.smembers("#{_jid}:results:created").to_a
        r.del "#{_jid}:events:errors", 
              "#{_jid}:events:warnings", 
              "#{_jid}:results:updated", 
              "#{_jid}:results:created"
      end
    end

    save_trends
    
    return []
  end

  # Adds an entry to the trends key in the task's metadata
  # Expects a key (which will be created or added to) and a hash
  # containing a list of key/values pairs t
  def save_trends(time_value=Time.now)
    

    _jid = @options.try(:[],"_params").try(:[],"_jid")
    if(_jid.blank?)
      return
    end
    trends = nil
    trend_options = nil
    Sidekiq.redis do |redis|
      redis.lock("#{_jid}:trends") do |lock|
        trends = redis.get("#{_jid}:trends")

        if(trends.present?)
          trends = JSON.parse(trends)
        else
          trends = {}
        end

        trend_options = redis.get("#{_jid}:trend_options")
        redis.del("#{_jid}:trends")
        redis.del("#{_jid}:trend_options")
        if(trend_options.present?)
          trend_options = JSON.parse(trend_options)
        else
          trend_options = {}
        end
      end
    end
    


    if trends.present? && trends.count > 0 && @options[:_self].present?

      trend_options ||= {}
      @options[:_self].metadata ||={}
      @options[:_self].metadata["trends"] ||={}
      trends.each do |key, counts|
        @options[:_self].metadata["trends"][key] ||= {"data"=>[]}
        if trend_options[key].try(:[],"chart_options").present?
          @options[:_self].metadata["trends"][key]["library"] = trend_options[key]["chart_options"]
        end

        if(trend_options[key].try(:[],"options").try(:[],"date_format").present?)
          date_value = time_value.strftime(trend_options[key].try(:[],"options").try(:[],"date_format"))
        else
          date_value = time_value.strftime("%b %d %Y %H:%M:%S")
        end

        counts.each do |trend_name, trend_value|
          series = @options[:_self].metadata["trends"][key]["data"].select{|el| el["name"] == trend_name }.first

          if(series.blank?)



            series = {"name"=> trend_name, "data" =>{ date_value => trend_value}}
            if defined?(trend_options) && trend_options.try(:[],key).try(:[],"series_options").try(:[],trend_name)
              series["library"] = trend_options[key]["series_options"][trend_name]
            end

            @options[:_self].metadata["trends"][key]["data"] << series
          else
            series["data"][date_value] = trend_value
          end
        end

      end
      if(trends.try(:[],"open_vulnerability_count").try(:[],"open"))
        @options[:_self].metadata["latest_results_link"] = {text: "#{trends.try(:[],"open_vulnerability_count").try(:[],"open").to_i} results", search:"q[metadata_search]=vulnerability_count:task_id:#{@options[:_self].id}>0"}
      end

    end
  end
end


module ScumblrWorkers
  class AsyncSidekiqWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    def perform(r, options)
      options ||={}
      @options = options.with_indifferent_access
      # Load based on id passed 
      Thread.current["sidekiq_job_id"] = @options.try(:[],"_params").try(:[],"_jid")
      begin
        self.perform_work(r)
      rescue=>e
        create_error("An error occurred: #{e.message}\r\n#{e.backtrace}")
      ensure
        Thread.current["sidekiq_job_id"] = nil
      end
    end

    private

    # This will at take a key and a hash with values and puts these values into the trends hash
    # if the key already exists in the trends hash it will sum the values together
    # example: @trends = {updated: {results: 1, tasks:10}},  key= :updated, count= {results: 5, tasks: 2}
    #   @trends will be updated to {updated: {results: 6, tasks: 12}}
    def update_trends(key, count, chart_options={}, series_options=[], options={})
      
      _jid = @options.try(:[],"_params").try(:[],"_jid")
      if(_jid.present?)
        Sidekiq.redis do |redis|
          redis.lock("#{_jid}:trends") do |lock|
            trends = redis.get("#{_jid}:trends")
            if(trends.present?)
              trends = JSON.parse(trends)
            else
              trends = {}
            end

            trend_options = redis.get("#{_jid}:trend_options")
            if(trend_options.present?)
              trend_options = JSON.parse(trend_options)
            else
              trend_options = {}
            end

            trend_options[key] ||= {}
            trend_options[key]["chart_options"] = chart_options
            trend_options[key]["series_options"] = series_options
            trend_options[key]["options"] = options
            trends[key] ||= Hash.new(0)
            trends[key] = [trends[key], count].inject(Hash.new(0)) { |memo, subhash| subhash.each { |prod, value| memo[prod] += value.to_f } ; memo }

            redis.set("#{_jid}:trends", trends.to_json)
            redis.set("#{_jid}:trend_options", trend_options.to_json)

          
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
      if(@options.try(:[],:_self).present?)
        eventable_id = @options.try(:[],:_self).class == Fixnum ? @options.try(:[],:_self) : @options.try(:[],:_self).try(:[],:id)
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
