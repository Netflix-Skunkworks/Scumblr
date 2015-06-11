class AddGroupToSearches < ActiveRecord::Migration
  def change
    add_column :searches, :group, :integer, default: 1
  end
end
