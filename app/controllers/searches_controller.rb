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
  before_filter :load_search, only: [:show, :edit, :update, :destroy]
  authorize_resource



  # GET /searches
  # GET /searches.json
  def index
    @searches = Search.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @searches }
    end
  end

  # GET /searches/1
  # GET /searches/1.json
  def show
    @provider_options = @search.provider.constantize.options

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @search }
    end
  end

  # GET /searches/new
  # GET /searches/new.json
  def new
    @search = Search.new
    @providers = SearchProvider::Provider.subclasses.map{|p| [p.to_s,p.provider_name]}



    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @search }
    end
  end

  # GET /searches/1/edit
  def edit
    @providers = SearchProvider::Provider.subclasses.map{|p| [p.to_s,p.provider_name]}

  end

  # POST /searches
  # POST /searches.json
  def create
    @search = Search.new(search_params)
    @providers = SearchProvider::Provider.subclasses.map{|p| [p.to_s,p.provider_name]}

    respond_to do |format|
      if @search.save
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
    @providers = SearchProvider::Provider.subclasses.map{|p| [p.to_s,p.provider_name]}

    respond_to do |format|
      if @search.update_attributes(search_params)
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
    @search.destroy

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
      respond_to do |format|
        format.html {redirect_to search_url(@search), :notice=>"Running search..."}
      end
    else

      SearchRunner.perform_async(nil)

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
      @statuses.sort!{|x,y| x["message"].to_s[0] <=> y["message"].to_s[0]}
    rescue Redis::CannotConnectError

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
    params.require(:search).permit(:name, :description, :provider, :query, :tag_list, :subscriber_list).merge(:options =>all_options)
  end


end
