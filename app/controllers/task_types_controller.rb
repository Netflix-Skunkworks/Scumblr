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


 def options
    authorize! :options, :task_type
    @task = Task.find_by_id(params[:id])
    @task_type = params[:task_type]


    if(Task.task_type_valid?(@task_type.to_s))
      #the line above validates the task is a valid (and safe) type so constantize is safe
      @task_type_options = @task_type.constantize.options 
      @task_type_configuration = @task_type.constantize.config_options if @task_type.constantize.respond_to?(:config_options)
      @task_type_description = @task_type.constantize.description if @task_type.constantize.respond_to?(:description)
    end

    respond_to do |format|
      format.js
    end

  end




end
