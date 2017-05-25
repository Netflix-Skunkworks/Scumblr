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

class Event < ActiveRecord::Base
  belongs_to :user
  belongs_to :eventable, polymorphic: true
  has_many :event_changes, :dependent => :delete_all

  before_save :update_fields

  #validates :action, :eventable_type, :eventable_id, presence: true
  validates :action, presence: true

  attr_accessor :field, :new_value, :old_value


  
  def new_value_to_s
    if(self.event_changes.length == 0)
      return ""
    elsif(self.event_changes.length == 1)
      return self.event_changes[0].new_value.to_s
    else
      return "Multiple"
    end
  end

  def old_value_to_s
    if(self.event_changes.length == 0)
      return ""
    elsif(self.event_changes.length == 1)
      return self.event_changes[0].old_value.to_s
    else
      return "Multiple"
    end
  end

  private

  def update_fields
    if(self.field)

      self.event_changes.build(field: self.field, new_value: self.new_value, old_value: self.old_value)
      self.field = nil
      self.new_value = nil
      self.old_value = nil
    end
    if(self.date.blank?)
      self.date = Time.now
    end
  end

  def field_name
    if(event_changes.length == 1)
      "#{event_changes.first.field}"
    elsif(event_changes.length == 0)
      "#{eventable_type}"
    else
      "Multiple"
    end
      
  end

  
  # Perform a ransack search against the results model
  # options:
  # => columns: which columns to select in the query
  # => sql_only: whether to return only the sql query text
  def self.perform_search(q, page=1, per=25, options={})


    q ||= {}
    @errors ||=[]
    if(q[:chronic_date_lteq].present?)
      @parsed_before_date = Chronic.parse(q[:chronic_date_lteq], context: :past)
      if(@parsed_before_date.nil?)
        @errors ||=[]
        @errors << "Could not parse \"Occurred Before\" date"
      else
        q[:date_lteq] = @parsed_before_date
      end
    end

    if(q[:chronic_date_gteq].present?)
      @parsed_after_date = Chronic.parse(q[:chronic_date_gteq], context: :past)
      if(@parsed_after_date.nil?)
        @errors ||=[]
        @errors << "Could not parse \"Occurred After\" date"
      else
        q[:date_gteq] = @parsed_after_date
      end
    end
    
    
    events = Event
    if(options[:columns])
      events = events.select(options[:columns])
    end


    events = events.includes(:eventable, :user).search(q.except([:chronic_date_lteq, :chronic_date_gteq]))
    events.sorts = 'created_at desc' if events.sorts.empty? && !options[:sql_only]==true
    

    if(options[:sql_only]==true)
      return [events, events.result.to_sql]
    else
      return [events, events.result.page(page).per(per).readonly(false)]
    end
  end



end

