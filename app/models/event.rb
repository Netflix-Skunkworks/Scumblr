class Event < ActiveRecord::Base
  belongs_to :user
  belongs_to :eventable, polymorphic: true

  before_save :update_fields

  validates :recipient, :action, :eventable_type, :eventable_id, presence: true

  private

  def update_fields
    if(self.date.blank?)
      self.date = Time.now
    end
  end

  def recipient_action
    "#{recipient} #{action}"
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
