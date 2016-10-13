class ChangeResultMetadataToJson < ActiveRecord::Migration
  def up
    
    rename_column :results, :metadata, :metadata_archive
    add_column :results, :metadata, :jsonb

    i = 0
    total = Result.all.count
    Result.all.each do |r|
      if(i%100 == 0)
        puts "#{i}/#{total} results complete"
      end
      r.metadata = r.metadata_archive
      r.save
      i+=1 

    end


  end

  def down
    
    # add_column :results, :metadata_archive, :text

    i = 0
    total = Result.all.count
    Result.all.each do |r|
      if(i%100 == 0)
        puts "#{i}/#{total} results complete"
      end
      r.metadata_archive = r.metadata
      r.save
      i+=1 

    end

    remove_column :results, :metadata
    rename_column :results, :metadata_archive, :metadata

  end

end
