class AddEnabledToSearches < ActiveRecord::Migration
  def change
    add_column :searches, :enabled, :boolean, default: true
  end
end
