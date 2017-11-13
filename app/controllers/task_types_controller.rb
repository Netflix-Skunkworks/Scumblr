#     Copyright 2016 Netflix, Inc.
#
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.


class TaskTypesController < ApplicationController
protect_from_forgery except: [:options, :on_demand_options]

 def options
    authorize! :options, :task_type
    @task = Task.find_by_id(params[:id])
    @task_type = params[:task_type] || @task.task_type


    if(Task.task_type_valid?(@task_type.to_s))
      #the line above validates the task is a valid (and safe) type so constantize is safe
      @task_type_options = @task_type.constantize.options if @task_type.constantize.respond_to?(:options)
      @task_type_configuration = @task_type.constantize.config_options if @task_type.constantize.respond_to?(:config_options)
      @task_type_description = @task_type.constantize.description if @task_type.constantize.respond_to?(:description)
      @callback_task = @task_type.constantize.callback_task? if @task_type.constantize.respond_to?(:callback_task?)
    end

    respond_to do |format|
    format.js
    end

  end

  def on_demand_options
    authorize! :on_demand_options, :task_type
    @task = Task.find_by_id(params[:id])
    @task_type = params[:task_type] || @task.task_type
    @require_required_fields = true
    if(Task.task_type_valid?(@task_type.to_s) && @task_type.constantize.respond_to?(:options))
      #the line above validates the task is a valid (and safe) type so constantize is safe
      task_class = @task_type.constantize

      @task_type_options, @task_options = nil



      if(task_class.method(:options).arity == 0 || params[:options].blank?)

        @task_options = @task.merge_options(params[:options])
        if(task_class.respond_to?(:prepare_options))
          @task_options = task_class.prepare_options(@task_options)
        end
        @task_type_options = task_class.options
      else
        @task_options = @task.merge_options(params[:options])
        if(task_class.respond_to?(:prepare_options))
          @task_options = task_class.prepare_options(@task_options)
        end

        @task_type_options = @task_type.constantize.options(@task_options)

      end



    end

    respond_to do |format|
      format.js
    end
  end




end
