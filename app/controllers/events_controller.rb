class EventsController < ApplicationController
  authorize_resource
  skip_before_filter :verify_authenticity_token, :only=>[:index]

  def index
    # @events = Event.all


    @objects = {
      events: {:method=>:event, :includes=>[:user, :eventable], :link=>{:method=>:id, :path=>:event_url, :params=>[:id], :sort_key=>:id}, :include_link=>[false, true], :attributes=>[:date, :eventable, :recipient, :action, :old_value, :new_value, :user], :labels=>[nil, "Associated with"], :sort_keys=>[:date,:eventable_id, :recipient, :action, :old_value, :new_value,:user_id], name:"Events"}
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
    @event_paginated = @events.page(params[:page]).per(params[:per_page]) if @events

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
      event: {keys: [:id, :recipient, :eventable, :action, :old_value, :new_value, :user, :source, :details], object: @event, :include_link=>[false, false, true]}
    }

  end



  private 

  def perform_search
    @total_event_count = Event.count


    if(params[:commit] == "Clear Search")
      session.delete(:saved_event_search)
      params.delete(:q)
    end

    if(params[:saved_event_filter_id].present?)
      @saved_event_filter = SavedFilter.find_by_id(params[:saved_event_filter_id])
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

    @q = Event.perform_search(params[:q])

    if(params[:commit] == "Save")
      @saved_filter = SavedFilter.new(saved_filter_type: "Event")
    end

    @events = @q.result(distinct:true)
  end


end
