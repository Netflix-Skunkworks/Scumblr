class RenameSearchesToTasks < ActiveRecord::Migration
  def change
    rename_table :searches, :tasks
    rename_column :tasks, :provider, :task_type

    Tagging.where(:taggable_type=>"Search").each do |t|
      t.update_attributes(taggable_type: "Task")
    end

    SavedFilter.all.each do |f|
      f.query["tasks_id_in"] = f.query.delete("searches_id_in")
      f.save
    end

    rename_table :search_results, :task_results
    rename_column :task_results, :search_id, :task_id

  end
end
