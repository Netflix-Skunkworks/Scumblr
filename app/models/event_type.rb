class EventType < ActiveRecord::Base
  has_many :events
  
  validates :name, uniqueness: true
  validates :name, presence: true

  def to_s
    name
  end
end
