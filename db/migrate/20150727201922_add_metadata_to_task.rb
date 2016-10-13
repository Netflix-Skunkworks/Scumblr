class AddMetadataToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :metadata, :jsonb
  end
end
