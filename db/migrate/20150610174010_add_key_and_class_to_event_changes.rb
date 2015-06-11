class AddKeyAndClassToEventChanges < ActiveRecord::Migration
  def change
    add_column :event_changes, :old_value_key, :integer
    add_column :event_changes, :new_value_key, :integer
    add_column :event_changes, :value_class, :string
  end
end
