class MakeEventsPolymorphic < ActiveRecord::Migration
  def change
    add_column :events, :eventable_type, :string, index: true
    rename_column :events, :result_id, :eventable_id
  end
end
