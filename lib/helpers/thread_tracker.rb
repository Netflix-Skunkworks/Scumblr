class ThreadTracker
  attr_accessor :current_thread
  # this expects the two required parameters from above
  def initialize()
  end

  def create_tracking_thread(calling_task)
    Thread.current[:current_task] = calling_task.try(:id).to_s
  end
end
