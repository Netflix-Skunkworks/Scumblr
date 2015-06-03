class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :recipient, index: true
      t.string :action, index: true
      t.string :old_value, index: true
      t.string :new_value, index: true
      t.string :source, index: true
      t.text :details
      t.datetime :date


      t.references :user, index: true
      t.references :result, index: true

      t.timestamps
    end
  end
end
