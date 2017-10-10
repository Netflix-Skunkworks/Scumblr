class AddFrequencyToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :frequency, :string, default: ""
  end
end
