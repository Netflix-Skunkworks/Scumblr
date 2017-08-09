class AddFrequencyToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :frequency, :interval
  end
end
