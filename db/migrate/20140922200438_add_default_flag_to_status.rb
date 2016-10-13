class AddDefaultFlagToStatus < ActiveRecord::Migration
  def change
    add_column :statuses, :default, :boolean, :default=>false
  end
end
