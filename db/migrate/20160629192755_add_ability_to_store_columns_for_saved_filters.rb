class AddAbilityToStoreColumnsForSavedFilters < ActiveRecord::Migration
  def change

    add_column :saved_filters, :store_index_columns, :boolean
    add_column :saved_filters, :index_columns, :text
  end
end
