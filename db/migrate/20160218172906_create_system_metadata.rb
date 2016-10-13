class CreateSystemMetadata < ActiveRecord::Migration
  def change
    create_table :system_metadata do |t|
      t.string :key


      t.timestamps
    end

    add_column :system_metadata, :metadata, :jsonb
  end
end
