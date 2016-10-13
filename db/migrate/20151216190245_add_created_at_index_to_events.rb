class AddCreatedAtIndexToEvents < ActiveRecord::Migration
  def change
    add_index :events, :created_at
  end
end
