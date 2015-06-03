class MakeSavedFiltersPolymorphic < ActiveRecord::Migration
  def change
    add_column :saved_filters, :saved_filter_type, :string

    SavedFilter.all.each do |f|
      f.saved_filter_type = "Result"
      f.save
    end
  end
end
