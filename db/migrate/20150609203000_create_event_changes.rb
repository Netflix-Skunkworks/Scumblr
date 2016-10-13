class CreateEventChanges < ActiveRecord::Migration
  def change
    create_table :event_changes do |t|
      t.references :event, index: true
      t.string :field
      t.text :new_value
      t.text :old_value

      t.timestamps
    end
  end
end
