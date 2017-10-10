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

class EventsController < ApplicationController
  authorize_resource
  skip_before_filter :verify_authenticity_token, :only=>[:index]

  def index
    @menu_item = "events"
    # @events = Event.all


    @objects = {
      events: {:method=>:event, :includes=>[:user, :eventable, :event_changes], :link=>{:method=>:id, :path=>:event_url, :params=>[:id], :sort_key=>:id}, :include_link=>[false, true], :attributes=>[:date, :eventable, :action, :user], :labels=>[nil, "Associated with"], :sort_keys=>[:date,:eventable_id, :action,:user_id], name:"Events"}
    }

    perform_search

    #Save is here because if we render/return in perform_search we end up double rendering
    if(params[:commit] == "Save")
      #We delete commit to prevent the parameter value from being picked up in pagination, etc.
      params.delete(:commit)
      render 'saved_filters/new'
      return
    end

    @event_count = Event.count
    @event_paginated = @events || []

    #We delete commit to prevent the parameter value from being picked up in pagination, etc.
    params.delete(:commit)


    # @objects.each do |key, result_set|
    #   sort = params[:sort].to_i == 0 ? result_set.try(:[], :link).try(:[],:sort_key) : result_set.try(:[],:sort_keys).try(:[],params[:sort].to_i - 1)
    #   # get_paginated_results(Event, result_set[:method], {includes: result_set[:includes], order: sort || :id , direction: params[:sort_dir] || :desc})
    # end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @result }
      format.js
    end
  end

  def show
    @event = Event.find_by_id(params[:id])

    @object =
    {
      event: {:includes=>[:user, :eventable, :event_changes], keys: [:id, :eventable, :action, :user, :source, :details], object: @event, :include_link=>[false, false, true]},
      event_changes: {:method=>:event_changes, :attributes=>[:field, :old_value, :new_value] }
    }

    @event_changes_paginated = @event.event_changes

  end



  private

  def perform_search
    @total_event_count = Event.count


    if(params[:commit] == "Clear Search")
      session.delete(:saved_event_search)
      params.delete(:q)
    end

    if(params[:saved_filter_id].present?)
      @saved_event_filter = SavedFilter.find_by_id(params[:saved_filter_id])
      params[:q] = @saved_event_filter.query
    end

    if(params[:q].blank? && session[:saved_event_search].present?)
      params[:q] = session[:saved_event_search]
    end

    if(params[:q].class == String)
      params[:q] = JSON.parse(params[:q])
    end

    params[:q] ||= {}

    if(params[:sort])
      sort = params[:sort].to_i == 0 ? @objects[:events].try(:[], :link).try(:[],:sort_key) : @objects[:events].try(:[],:sort_keys).try(:[],params[:sort].to_i - 1)
      params[:q][:s] = "#{sort} #{params[:sort_dir] || desc}" if sort
    end

    params[:q].reject! {|k,v| v.blank? || v==[""]} if params[:q]

    session[:saved_event_search] = params[:q]


    @errors ||=[]
    if(params[:q][:chronic_date_lteq].present?)
      @parsed_before_date = Chronic.parse(params[:q][:chronic_date_lteq], context: :past)
      if(@parsed_before_date.nil?)
        @errors ||=[]
        @errors << "Could not parse \"Occurred Before\" date"

      end
    end

    if(params[:q][:chronic_date_gteq].present?)
      @parsed_after_date = Chronic.parse(params[:q][:chronic_date_gteq], context: :past)
      if(@parsed_after_date.nil?)
        @errors ||=[]
        @errors << "Could not parse \"Occurred After\" date"
      end
    end


    page = params[:page] || 1
    per = params[:per_page] || 25
    @q, @events = Event.perform_search(params[:q], page, per)

    if(params[:commit] == "Save")
      @saved_filter = SavedFilter.new(saved_filter_type: "Event")
    end




  end


end
