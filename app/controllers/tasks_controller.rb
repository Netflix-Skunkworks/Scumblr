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

class TasksController < ApplicationController
  before_filter :load_task, only: [:show, :edit, :update, :destroy, :enable, :disable, :get_metadata]
  authorize_resource
  skip_before_action :verify_authenticity_token, only: [:run]


  # GET /tasks
  # GET /tasks.json
  def index
    @menu_item = "tasks"
    @tasks = Task.all.order(:name)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tasks }
    end
  end

  # GET /tasks/1
  # GET /tasks/1.json
  def show
    if (Task.task_type_valid?(@task.task_type))

      @task_type_options = @task.task_type.constantize.options
    else
      @task_type_options = []
    end

    @associated_objects = {
      events: {:method=>:events, :includes=>[:user, :event_changes], :link=>{:method=>:id, :path=>:event_url, :params=>[:id], :sort_key=>:id}, :attributes=>[:date, :action, :user], :sort_keys=>[:date, :action, :user_id], name:"Events"}
    }

    if(params[:action_name].present?)
      @associated_objects = @associated_objects.select{|k,obj| obj[:method].to_s == params[:action_name].to_s}

    end

    @associated_objects.each do |key, result_set|
      sort = params[:sort].to_i == 0 ? result_set.try(:[], :link).try(:[],:sort_key) : result_set.try(:[],:sort_keys).try(:[],params[:sort].to_i - 1)

      get_paginated_results(@task, result_set[:method], {includes: result_set[:includes], order: sort || :id , direction: params[:sort_dir] || :desc})
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @task }
      format.js
    end
  end

  # GET /tasks/new
  # GET /tasks/new.json
  def new
    @task = Task.new
    @task_types = task_types

    if(params[:task_id].present?)
      @original_task = Task.where(id: params[:task_id]).first
      if(@original_task)
        @task.name = @original_task.name + " (Copy)"

        @task.task_type = @original_task.task_type
        @task.options = @original_task.options
        @task.description = @original_task.description + " Copied from Task #{@original_task.id}"
        @task.query = @original_task.query
        @task.enabled = @original_task.enabled
        @task.group = @original_task.group
      end
    end




    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @task }
    end
  end

  # GET /tasks/1/edit
  def edit
    @task_type = @task.task_type
    @task_types = task_types

    if(Task.task_type_valid?(@task_type.to_s))
      #the line above validates the task is a valid (and safe) type so constantize is safe
      @task_type_configuration = @task_type.constantize.config_options if @task_type.constantize.respond_to?(:config_options)
      @task_type_description = @task_type.constantize.description if @task_type.constantize.respond_to?(:description)
    end
    @task_type_configuration = @task_type.constantize.config_options if @task_type.constantize.respond_to?(:config_options)
    @task_type_description = @task_type.constantize.description if @task_type.constantize.respond_to?(:description)

  end

  # POST /tasks
  # POST /tasks.json
  def create

    @task = Task.new(task_params)

    @task_types = task_types
    if(Task.task_type_valid?(@task.task_type) && @task.task_type.constantize.respond_to?(:callback_task?) && @task.task_type.constantize.callback_task? == true)
      @task.run_type = "callback"
    elsif(params[:on_demand] =="1")
      @task.run_type = "on_demand"
      @task.metadata ||={}
      if(params[:runtime_override_all] == "1")
        @task.metadata["runtime_override"] = true
      else
        @task.metadata["runtime_override"] = params.try(:[],:task).try(:[], :options).try(:[], :runtime_override).to_a.reject(&:blank?)
      end
    else
      @task.run_type = "scheduled"
    end

    respond_to do |format|
      if @task.save
        @task.events << Event.create(field: "Task", action: "Created", user_id: current_user.id)
        format.html { redirect_to @task, notice: 'Task was successfully created.' }
        format.json { render json: @task, status: :created, location: @task }
      else
        format.html { render action: "new" }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tasks/1
  # PUT /tasks/1.json
  def update

    @task_types = task_types
    if(Task.task_type_valid?(@task.task_type) && @task.task_type.constantize.respond_to?(:callback_task?) && @task.task_type.constantize.callback_task? == true)
      @task.run_type = "callback"
    elsif(params[:on_demand] =="1")
      @task.run_type = "on_demand"
      @task.metadata ||={}
      if(params[:runtime_override_all] == "1")
        @task.metadata["runtime_override"] = true
      else
        @task.metadata["runtime_override"] = params.try(:[],:task).try(:[], :options).try(:[], :runtime_override).to_a.reject(&:blank?)
      end
    else
      @task.run_type = "scheduled"
    end

    respond_to do |format|
      if @task.update_attributes(task_params)
        @task.events << Event.create(field: "Task", action: "Updated", user_id: current_user.id)
        format.html { redirect_to @task, notice: 'Task was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.json
  def destroy
    task_id = @task.id
    @task.unschedule_from_sidekiq
    @task.destroy
    @task.events << Event.create(field: "Task", action: "Deleted", user_id: current_user.id, eventable_type:"Task", eventable_id: task_id)

    respond_to do |format|
      format.html { redirect_to tasks_url }
      format.json { head :no_content }
    end
  end

  def run

    if(params[:id].present?)
      if(request.method == "POST")
        task_params = request.body.read
      else
        task_params = nil
      end
      load_task

      #@task.perform_task
      if(@task.run_type == "on_demand")
        TaskRunner.perform_async(@task.id, task_params, params.try(:[],"task").try(:[],"options"))
      else
        TaskRunner.perform_async(@task.id, task_params)
      end
      @task.events << Event.create(field: "Task", action: "Run", user_id: current_user.id)
      respond_to do |format|
        format.html {redirect_to task_url(@task), :notice=>"Running task..."}
      end
    elsif(params[:task_type].present?)

    else


      TaskRunner.perform_async(nil)
      task_ids = Task.where(enabled:true, run_type: "scheduled").map{|s| s.id}
      events = []
      task_ids.each do |s|
        events << Event.new(date: Time.now, field: "Task", action: "Run", user_id: current_user.id, eventable_type: "Task", eventable_id: s)
      end
      Event.import events

      respond_to do |format|
        format.html {redirect_to tasks_url, :notice=>"Running all tasks..."}
      end
    end

  end

  def events
    @statuses = []
    begin
      Sidekiq::Workers.new.each do |k,k2,v|
        @statuses << Sidekiq::Status.get_all(v["payload"]["jid"])
      end
      @statuses.sort!{|x,y| x["message"].to_s[0].to_s <=> y["message"].to_s[0].to_s}
    rescue Redis::CannotConnectError
    end
  end

  def enable
    if(@task && @task.enabled != true)
      @task.enabled = true
      @task.save
      @task.events << Event.create(field: "Task", action: "Enabled", user_id: current_user.id)
      message = "Task enabled"
    end

    respond_to do |format|
      format.html { redirect_to tasks_url, notice: message || "Could not enable task" }
      format.json { head :no_content }
    end

  end

  def disable
    if(@task && @task.enabled == true)
      @task.enabled = false
      @task.save
      @task.events << Event.create(field: "Task", action: "Disabled", user_id: current_user.id)
      message = "Task disabled"
    end

    respond_to do |format|
      format.html { redirect_to tasks_url, notice: message || "Could not disable task" }
      format.json { head :no_content }
    end
  end

  def bulk_update
    task_ids = params[:task_ids] || []
    task_ids.uniq!
    if(task_ids.present?)
      events = []
      if(params[:commit] == "Change Group" && params[:group_id] =~ /^[0-9]+$/)
        #validated group_id is a number above so should be safe here
        Task.where({:id=>task_ids}).update_all({:group => params[:group_id]})
        task_ids.each do |s|
          #TODO: Add event changes for each task
          events << Event.new(date: Time.now, action: "Updated", user_id: current_user.id, eventable_type:"Task", eventable_id: s)
        end

        message = "Task group updated."

      elsif(params[:commit] == "Enable")
        Task.where({:id=>task_ids}).update_all({:enabled => true})
        Task.update_schedules
        task_ids.each do |s|
          events << Event.new(date: Time.now, action: "Enabled", user_id: current_user.id, eventable_type:"Task", eventable_id: s)
        end

        message = "Tasks enabled."

      elsif(params[:commit] == "Disable")
        Task.where({:id=>task_ids}).update_all({:enabled => false})
        Task.update_schedules
        task_ids.each do |s|
          events << Event.new(date: Time.now, action: "Disabled", user_id: current_user.id, eventable_type:"Task", eventable_id: s)
        end

        message = "Tasks disabled."
      elsif(params[:commit] == "Delete")
        Task.where({:id=>task_ids}).delete_all
        Task.update_schedules
        task_ids.each do |s|
          events << Event.new(date: Time.now, action: "Disabled", user_id: current_user.id, eventable_type:"Task", eventable_id: s)
        end

        message = "Tasks deleted."
      elsif(params[:commit] == "Run")
        valid_tasks = []
        task_ids.each do |t|
          task = Task.find_by_id(t)
          if(task)
            valid_tasks << t
            events << Event.new(date: Time.now, action: "Run", user_id: current_user.id, eventable_type:"Task", eventable_id: t)
          end
        end
        TaskRunner.perform_async(valid_tasks)

        message = "Running tasks."

      end
      Event.import events
    else
      message = "No tasks selected to update."
    end

    respond_to do |format|
      format.html { redirect_to tasks_url, notice: message || "Could not update results" }
      format.json { head :no_content }
    end

  end

  def schedule
    task_ids = params[:task_ids] || []
    task_ids.uniq!
    if(task_ids.present?)
      events = []
      if(params[:commit] == "Schedule")
        day = params[:day] || "*"
        hour = params[:hour] || "*"
        minute = params[:minute] || "*"
        month = params[:month] || "*"
        day_of_week = params[:day_of_week] || "*"

        task_ids.each do |s|
          Task.find(s).schedule_with_params(minute, hour, day, month, day_of_week)
          events << Event.new(date: Time.now, action: "Scheduled", user_id: current_user.id, eventable_type:"Task", eventable_id: s)
        end

        message = "Tasks scheduled."
      elsif(params[:commit] == "Unschedule")
        task_ids.each do |s|
          Task.find(s).unschedule
          events << Event.new(date: Time.now, action: "Unscheduled", user_id: current_user.id, eventable_type:"Task", eventable_id: s)
        end

        message = "Tasks unscheduled."
      end

      Event.import events
    else
      message = "No tasks selected to schedule."
    end

    respond_to do |format|
      format.html {redirect_to tasks_url, notice: message || "Could not schedule tasks" }
    end
  end

  def get_metadata

    response = @task.metadata

    respond_to do |format|
      format.json { render json: response.to_json, layout: false}
    end

  end

  def summary
    @task = Task.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def expandall
    @tasks = Task.all
    respond_to do |format|
      format.js
    end
  end

  def search
    q_param = params[:q]
    page = params[:page]
    per_page = params[:per_page]
    resolve_system_metadata = params[:resolve_system_metadata]
    system_metadata = []
    metadata_hash = {}
    @q = Task.ransack q_param
    @tasks = @q.result.page(page).per(per_page)

    if resolve_system_metadata == "true"
      @system_metadata = []
      @tasks.each do | task|
        if (Task.task_type_valid?(task.task_type))
          @task_type_options = task.task_type.constantize.options
        else
          @task_type_options = []
        end
        @task_type_options.each do |key,v|
          if v[:type] == :system_metadata and task.options[key].present?
            system_metadata << task.options[key].to_i
            # moved this from array to hash
            metadata_hash[task.id.to_s.to_sym] ||= {}
            metadata_hash[task.id.to_s.to_sym].merge!({"#{key}": task.options[key].to_i})
          end
        end
      end

      system_metadata_objects = SystemMetadata.where(id: system_metadata)

      metadata_hash.each_with_index do |(task, value), index|
        value.each do | key,data |
          metadata_hash[task][key] = system_metadata_objects.where(id: data.to_i).first.metadata
        end
      end
      @updated_tasks = []
      @tasks.each do | task|
        if metadata_hash.keys.include? task.id.to_s.to_sym
          task.options.merge!(metadata_hash[task.id.to_s.to_sym])
          @updated_tasks << task
        else
          @updated_tasks << task
        end
      end
      render json: @updated_tasks.to_json
    else
      render json: @tasks.to_json
    end

  end

  private

  def load_task
    @task = Task.find(params[:id])
  end


  def task_params
    all_options = params.require(:task).fetch(:options, nil).try(:permit!)
    params.require(:task).permit(:name, :description, :task_type, :query, :tag_list, :subscriber_list, :group, :enabled, :frequency).merge(:options =>all_options)
  end

  def task_types
    task_types = {}
    task_types["Search Providers (Legacy)"] = SearchProvider::Provider.subclasses.map{|p| [p.to_s,p.provider_name]}
    task_types.merge!(ScumblrTask::Base.descendants.reject{|x| !x.task_type_name }.sort_by{|x| x.to_s}.map{|t| [t.to_s, t.task_category, t.task_type_name]}.group_by{|t| t.try(:[],1) || "Generic"})
    task_types
  end

end
