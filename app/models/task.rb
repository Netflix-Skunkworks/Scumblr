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


class Task < ActiveRecord::Base
  #  attr_accessible :description, :name, :options, :task_type, :query, :tag_list

  has_many :taggings, as: :taggable, :dependent => :delete_all
  has_many :tags, through: :taggings
  has_many :subscribers, as: :subscribable
  has_many :task_results
  has_many :results, through: :task_results
  has_many :events, as: :eventable

  serialize :options, Hash
  # serialize :metadata, JSON



  validates :name, presence: true
  validates :name, uniqueness: true
  validates :group, presence: true
  validate :validate_search



  accepts_nested_attributes_for :taggings, :tags

  def to_s
    "Task #{id}"
  end

  def self.task_type_valid?(task_type)
    task_type.match(/\ASearchProvider::|\AScumblrTask::/) && (SearchProvider::Provider.subclasses.include?(task_type.to_s.constantize) || ScumblrTask::Base.descendants.reject{|x| !x.task_type_name }.include?(task_type.to_s.constantize))
  end

  def validate_search
    begin
      if(!Task.task_type_valid?(task_type))
        errors.add :task_type, " must be specified"
        return
      end
    rescue
      errors.add :task_type, " must be specified"
      return
    end


    task_type_options = self.task_type.constantize.options
    if(self.options.blank?)
      self.options = {}
    end
    self.options.slice!(*task_type_options.keys)
    task_type_options.each do |key, value|
      if value[:required] && options[key].blank?
        errors.add value[:name], " can't be blank"
      end
    end
    true
  end

  def task_type_name
    begin
      type = self.task_type.to_s.constantize
      if defined? type.provider_name
        type.provider_name
      elsif defined? type.task_type_name
        type.task_type_name
      end
    rescue
      ""
    end
  end

  def task_type_options
    begin
      self.task_type.try(:constantize).try(:options) || {}
    rescue
      {}
    end
  end

  def tag_list
    tags.map(&:name).join(",")
  end

  def tag_list=(names)
    self.tags = names.split(",").map do |n|
      tag = Tag.where("lower(name) like lower(?)",n.strip).first_or_initialize
      tag.name = n if tag.new_record?
      tag.save if tag.changed?
      tag
    end
  end

  def subscriber_list
    subscribers.where(:user_id=>nil).map(&:email).join(",")
  end

  def subscriber_list=(emails)
    self.subscribers = emails.split(",").map do |email|
      self.subscribers.where(:email=>email.downcase.strip).first_or_initialize
    end
  end

  def perform_task
    t = Time.now
    task = self
    task.metadata ||= {}
    Rails.logger.debug "Running #{task}"
    was_successful = false
    if(!Task.task_type_valid?(task.task_type))
      Rails.logger.error "Invalid task type #{task.task_type}"
      return
    end

    task_type = task.task_type.constantize

    task_options = task.options.merge({_metadata:task.metadata||{}, _self:task})


    results = nil
    begin
      task.metadata["_start_time"] = Time.now
      if(task.task_type.match(/\ASearchProvider::/))
        results = task_type.new(task.query, task_options).run
      else
        results = task_type.new(task_options).run
      end
    rescue StandardError=>e
      event = Event.create(action: "Error", source:"Task: #{task.name}", details: "Unable to run task #{task.name}.\n\nError: #{e.message}\n\n#{e.backtrace}", eventable_type: "Task", eventable_id: task.id )
      Rails.logger.error "#{e.message}"

      Thread.current["current_events"] ||= {}

      Thread.current["current_events"][event.action] ||= []
      Thread.current["current_events"][event.action] << event.id
      task.metadata["_last_run"] = Time.now
      task.metadata["_last_status"] = "Failed"
      unless event.details.nil?
        task.metadata["_last_status_message"] = event.details.truncate(50)
      else
        task.metadata["_last_status_message"] = "Exception for task #{task.id} (#{task.name})"
      end
      task.metadata["_last_status_event"] = event.id
      task.save
    else
      event = Event.create(field: "Task", action: "Complete", source: "Task: #{task.name}", details: "Task completed in #{Time.now-t} seconds", eventable_type: "Task", eventable_id: task.id )
      #Thread.current["current_events"][event.action] << event.id
      was_successful = true
      #task.metadata["_last_run"]  = task.metadata["_last_successful_run"] = Time.now
      task.metadata["_last_status"] = "Success"
      task.metadata["_last_status_event"] = event.id
      unless event.details.nil?
        task.metadata["_last_status_message"] = event.details.truncate(50)
      else
        task.metadata["_last_status_message"] = "Task completed"
      end
      task.save
    end

    if(results.blank?)

      # puts Thread.current["current_events"]
      unless Thread.current["current_events"].nil?
        task.metadata.merge!({"current_events": Thread.current["current_events"]})
      end
      unless Thread.current["current_results"].nil?
        task.metadata.merge!({"current_results": Thread.current["current_results"]})
      end
      if was_successful
        task.metadata["_last_run"] = task.metadata["_last_successful_run"] = Time.now
      end
      task.save
      Thread.current["current_results"] = {}
      Thread.current["previous_results"] = {}
      Thread.current["current_events"] = {}
      Thread.current["previous_events"] = {}
      Rails.logger.debug "No results returned"
      return
    end


    Rails.logger.debug "Results #{results}"
    new_status = Status.find_by_default(true).try(:id)

    counter = 0
    #foo = []
    results.each do |r|

      result = Result.where(:url=>r[:url].strip).first_or_initialize
      result.title = r[:title]
      result.domain = r[:domain]
      result.metadata = (result.metadata || {}).deep_merge(r[:metadata] || {})
      result.status_id = new_status if !result.status_id && new_status


      if result.changed?
        result.save
      end

      task.tags.each do |tag|
        tagging = result.taggings.where(:tag_id=>tag.id).first_or_initialize
        if tagging.changed?
          result.events << Event.create(field: "Tag", action: "Created",source: self.name.to_s, new_value: tag.name_value)

          tagging.save
        end
      end
      Rails.logger.warn "Result saved #{result}"

      task_result = TaskResult.where({:task_id=>task.id, :result_id=> result.id}).first_or_initialize
      task_result.save
      Rails.logger.warn "Task result saved #{task_result}"
    end
    results = nil
    # Sync up and merge all the results and events changed
    unless Thread.current["current_events"].nil?
      task.metadata.merge!({"current_events": Thread.current["current_events"]})
    end
    unless Thread.current["current_results"].nil?
      task.metadata.merge!({"current_results": Thread.current["current_results"]})
    end
    Thread.current["current_results"] = {}
    Thread.current["previous_results"] = {}
    Thread.current["current_events"] = {}
    Thread.current["previous_events"] = {}
    if was_successful
      task.metadata["_last_run"]  = task.metadata["_last_successful_run"] = Time.now
    end
    task.save!
    return nil
  end

end
