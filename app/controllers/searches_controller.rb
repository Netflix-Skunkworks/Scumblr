#     Copyright 2014 Netflix, Inc.
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


class SearchesController < ApplicationController
  before_filter :load_search, only: [:show, :edit, :update, :destroy, :enable, :disable]
  authorize_resource



  # GET /searches
  # GET /searches.json
  def index
    @searches = Search.all.group_by(&:group)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @searches }
    end
  end

  # GET /searches/1
  # GET /searches/1.json
  def show

    if (@search.provider.match(/\ASearchProvider::/) && SearchProvider::Provider.subclasses.include?(@search.provider.to_s.constantize) )
      @provider_options = @search.provider.constantize.options
    else
      @provider_options = []
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @search }
    end
  end

  # GET /searches/new
  # GET /searches/new.json
  def new
    @search = Search.new
    @providers = search_providers



    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @search }
    end
  end

  # GET /searches/1/edit
  def edit
    @providers = search_providers

  end

  # POST /searches
  # POST /searches.json
  def create
    @search = Search.new(search_params)
    @providers = search_providers

    respond_to do |format|
      if @search.save
        @search.events << Event.create(recipient: "Search", action: "Created", user_id: current_user.id)
        format.html { redirect_to @search, notice: 'Search was successfully created.' }
        format.json { render json: @search, status: :created, location: @search }
      else
        format.html { render action: "new" }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /searches/1
  # PUT /searches/1.json
  def update
    @providers = search_providers

    respond_to do |format|
      if @search.update_attributes(search_params)
        @search.events << Event.create(recipient: "Search", action: "Updated", user_id: current_user.id)
        format.html { redirect_to @search, notice: 'Search was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /searches/1
  # DELETE /searches/1.json
  def destroy
    search_id = @search.id
    @search.destroy
    @search.events << Event.create(recipient: "Search", action: "Deleted", user_id: current_user.id, eventable_type:"Search", eventable_id: search_id)

    respond_to do |format|
      format.html { redirect_to searches_url }
      format.json { head :no_content }
    end
  end

  def run
    if(params[:id].present?)
      load_search

      #@search.perform_search
      SearchRunner.perform_async(@search.id)
      @search.events << Event.create(recipient: "Search", action: "Run", user_id: current_user.id)
      respond_to do |format|
        format.html {redirect_to search_url(@search), :notice=>"Running search..."}
      end
    else

      SearchRunner.perform_async(nil)
      search_ids = Search.where(enabled:true).map{|s| s.id}
      events = []
      search_ids.each do |s|
        events << Event.new(date: Time.now, recipient: "Search", action: "Run", user_id: current_user.id, eventable_type: "Search", eventable_id: s)
      end
      Event.import events

      respond_to do |format|
        format.html {redirect_to searches_url, :notice=>"Running all searches..."}
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
    if(@search && @search.enabled != true)
      @search.enabled = true
      @search.save
      @search.events << Event.create(recipient: "Search", action: "Enabled", user_id: current_user.id)
      message = "Search enabled"
    end

    respond_to do |format|
      format.html { redirect_to searches_url, notice: message || "Could not enable search" }
      format.json { head :no_content }
    end

  end

  def disable
    if(@search && @search.enabled == true)
      @search.enabled = false
      @search.save
      @search.events << Event.create(recipient: "Search", action: "Disabled", user_id: current_user.id)
      message = "Search disabled"
    end

    respond_to do |format|
      format.html { redirect_to searches_url, notice: message || "Could not disable search" }
      format.json { head :no_content }
    end
  end

  def bulk_update
    search_ids = params[:search_ids] || []
    search_ids.uniq!
    if(search_ids.present?)
      events = []
      if(params[:commit] == "Change Group")

        Search.update_all({:group => params[:group_id]}, {:id=>search_ids}) 
        search_ids.each do |s|
          events << Event.new(date: Time.now, recipient: "Search", action: "Updated", user_id: current_user.id, eventable_type:"Search", eventable_id: s)
        end
        
        message = "Search group updated."

      elsif(params[:commit] == "Enable")
        Search.update_all({:enabled => true}, {:id=>search_ids}) 
        search_ids.each do |s|
          events << Event.new(date: Time.now, recipient: "Search", action: "Enabled", user_id: current_user.id, eventable_type:"Search", eventable_id: s)
        end
      
        message = "Searches enabled."

      elsif(params[:commit] == "Disable")
        Search.update_all({:enabled => false}, {:id=>search_ids}) 
        search_ids.each do |s|
          events << Event.new(date: Time.now, recipient: "Search", action: "Disabled", user_id: current_user.id, eventable_type:"Search", eventable_id: s)
        end

        message = "Searches disabled."
      elsif(params[:commit] == "Delete")
        Search.where({:id=>search_ids}).delete_all
        search_ids.each do |s|
          events << Event.new(date: Time.now, recipient: "Search", action: "Disabled", user_id: current_user.id, eventable_type:"Search", eventable_id: s)
        end

        message = "Searches deleted."
      elsif(params[:commit] == "Run")
        valid_searches = []
        search_ids.each do |s|
          search = Search.find_by_id(s)
          if(search)
            valid_searches << s
            events << Event.new(date: Time.now, recipient: "Search", action: "Run", user_id: current_user.id, eventable_type:"Search", eventable_id: s)
          end
        end
        SearchRunner.perform_async(valid_searches)

        message = "Running searches."

      end

      Event.import events
    else
      message = "No searches selected to update."
    end

    respond_to do |format|
      format.html { redirect_to searches_url, notice: message || "Could not update results" }
      format.json { head :no_content }
    end

  end


  private

  def load_search
    @search = Search.find(params[:id])
  end

  #  attr_accessible :description, :name, :options, :provider, :query, :tag_list
  #accepts_nested_attributes_for :taggings, :tags
  def search_params
    all_options = params.require(:search).fetch(:options, nil).try(:permit!)
    params.require(:search).permit(:name, :description, :provider, :query, :tag_list, :subscriber_list, :group, :enabled).merge(:options =>all_options)
  end

  def search_providers
    SearchProvider::Provider.subclasses.map{|p| [p.to_s,p.provider_name]}.sort
  end


end
