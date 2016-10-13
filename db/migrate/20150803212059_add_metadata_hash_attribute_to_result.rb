class AddMetadataHashAttributeToResult < ActiveRecord::Migration
  def up
    add_column :results, :metadata_hash, :string

    num_results = Result.count
    Result.all.each_with_index do |r,i|
      puts "Updating #{i}/#{num_results}" if i%10 == 0

      r.update_columns(metadata_hash: r.metadata.hash.to_s)
      
    end
  end

  def down
    remove_column :results, :metadata_hash
  end
end
