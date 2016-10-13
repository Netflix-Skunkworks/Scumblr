class RemoveChangeFieldsFromEvent < ActiveRecord::Migration
  def change
    remove_column :events, :new_value
    remove_column :events, :old_value
    remove_column :events, :recipient
  end
end
