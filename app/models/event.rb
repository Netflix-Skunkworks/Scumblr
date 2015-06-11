class Event < ActiveRecord::Base
  belongs_to :user
  belongs_to :eventable, polymorphic: true
  has_many :event_changes

  before_save :update_fields

  #validates :action, :eventable_type, :eventable_id, presence: true
  validates :action, presence: true

  attr_accessor :field, :new_value, :old_value


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

  def eventable_link
    "#{eventable_type} #{eventable_id}"
  end

    def self.perform_search(q)
    events = Event.includes(:eventable, :user).search(q)
    events.sorts = 'created_at desc' if events.sorts.empty?
    events
  end



end



# r = Result.new(url:"http://#{SecureRandom.hex}.com")
# e = r.events.build(action: "test")
# e.event_changes.build(field: "test_field")
# e.recipient ="autorecip"
# e.new_value = 2
# e.old_value = "-1"

# r.save