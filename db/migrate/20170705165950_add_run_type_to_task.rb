class AddRunTypeToTask < ActiveRecord::Migration
  def up
    add_column :tasks, :run_type, :string, default: "scheduled"

    Task.all.each do |t|
      
      if(Task.task_type_valid?(t.task_type))
        
        task_type = t.task_type.constantize
        
        if(task_type.respond_to?(:callback_task?) && task_type.callback_task? == true)
          t.run_type = "callback"
          t.save(validate: false)
        elsif(task_type.respond_to?(:on_demand_task?) && task_type.on_demand_task? == true)
          t.run_type = "on_demand"
          t.save(validate: false)
        else
          t.run_type = "scheduled"
          t.save(validate: false)
        end
      end

    end
  end

  def down
    remove_column :tasks, :run_type
  end
end
