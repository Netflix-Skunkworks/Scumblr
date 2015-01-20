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


require 'open-uri'

class ResultsController < ApplicationController
  authorize_resource
  skip_before_filter :verify_authenticity_token, :only=>[:index, :update_screenshot]

  before_filter :load_result, only: [:show, :edit, :update, :destroy, :tag, :action,
                                     :flag, :update_status, :comment, :delete_tag, :assign, :add_attachment, :delete_attachment,
                                     :subscribe, :unsubscribe, :update_screenshot]

  skip_authorize_resource :only=>:update_screenshot
  skip_authorization_check :only=>:update_screenshot
  skip_before_filter :authenticate_user!, :only=>:update_screenshot

  # GET /results
  # GET /results.json
  def index

    

    perform_search

    #Save is here because if we render/return in perform_search we end up double rendering
    if(params[:commit] == "Save")
      #We delete commit to prevent the parameter value from being picked up in pagination, etc.
      params.delete(:commit)
      render 'saved_filters/new'
      return
    end

    @results = @results.page(params[:page]).per(params[:per_page]) if @results

    #We delete commit to prevent the parameter value from being picked up in pagination, etc.
    params.delete(:commit)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @results }
    end
  end


  def dashboard


    #Add boxes at the top with Quick facts (New today (delta))......
    # Providers/Search with highest/lowest signal to noise ratio
    # Providers/Search with most/least raw actionable results
    #

    @results = Result.all
    @flags = Flag.all
    @results_by_date = Result.where(:id=>@results).group("date(created_at)").order("date(created_at)").count
    @statuses= Status.all
    @searches = Search.all


    @flag_counts = ResultFlag.includes(:flag).where(:result_id=>@results).group("flags.name").count

    @search_results_total = Search.joins(:search_results).group("searches.id").count
    @search_results_24_hours = Search.joins(:search_results).group("searches.id").where("search_results.created_at > ?",1.day.ago).count
    @search_results_7_days = Search.joins(:search_results).group("searches.id").where("search_results.created_at > ?",7.days.ago).count
    @search_results_30_day_trend = Search.joins(:search_results).where("search_results.created_at > ?",30.days.ago).count(:group=>["searches.id", "date(search_results.created_at)"], :order=>"date(search_results.created_at)")


    @search_results_without_flags = Search.joins(:results).where.not(:id=>ResultFlag.select(:id)).references(:results).group("searches.id").count
    @search_results_with_flags = Search.joins(:results=>:flags).group(["searches.id", "flags.id"]).count


    render layout: "dashboard"

  end


  # GET /results/1
  # GET /results/1.json
  def show

    @comments = @result.root_comments.includes([:user,:children])

    @associated_objects = [
      {:method=>:search_results, :includes=>:search, :link=>{:method=>:search_id, :path=>:search_url, :params=>[:search_id]}, :attributes=>[:search_name, :provider, :query, :created_at], name:"Results"},
    ]

    @associated_objects.each do |result_set|
      get_paginated_results(@result, result_set[:method], result_set[:includes])
    end


    if(params[:action_name])
      @associated_objects = @associated_objects.select{|obj| obj[:method].to_s == params[:action_name].to_s}
    end



    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @result }
      format.js
    end
  end

  # GET /results/new
  # GET /results/new.json
  def new
    @result = Result.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @result }
    end
  end

  # GET /results/1/edit
  def edit

  end

  # POST /results
  # POST /results.json
  def create
    @result = Result.new(result_params)
    @result.status = Status.find_by_default(true)

    respond_to do |format|
      if @result.save
        format.html { redirect_to @result, notice: 'Result was successfully created.' }
        format.json { render json: @result, status: :created, location: @result }
      else
        format.html { render action: "new" }
        format.json { render json: @result.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /results/1
  # PUT /results/1.json
  def update

    respond_to do |format|
      if @result.update_attributes(result_params)
        format.html { redirect_to @result, notice: 'Result was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @result.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_status
    @status = Status.find(params[:status_id])

    @result.status_id= @status.id
    @result.save
    @notice = "Status updated."

    respond_to do |format|

      format.js
    end

  end

  # DELETE /results/1
  # DELETE /results/1.json
  def destroy
    @result.destroy

    respond_to do |format|
      format.html { redirect_to results_url }
      format.json { head :no_content }
    end
  end

  def comment
    @comment = Comment.build_from( @result, current_user.id, params[:comment] )


    if(params[:parent_id] && parent = Comment.find_comments_for_commentable(Result, @result).find(params[:parent_id]))
      @comment.parent_id = params[:parent_id]
    end
    @comment.save


    redirect_to :back, notice: "Comment Added"
  end

  def delete_tag
    @result.taggings.where(:tag_id=>params[:tag_id]).delete_all
    redirect_to :back, notice: "Tag removed."

  end

  def assign
    @user = User.find(params[:user_id])

    @result.user_id = @user.id
    @result.save

    respond_to do |format|
      format.js
    end



  end

  def flag

    @notice=""
    @options=""

    if(@result.flags.map(&:id).include?(params[:flag].to_i))
      @notice = "Result already flagged!"
      return
    end

    @flag = Flag.find_by_id(params[:flag])
    @result_flag = @result.result_flags.where(:flag_id => @flag.id, :workflow_id=>@flag.workflow_id).first_or_initialize




    @errors = @result_flag.validate_actions(@flag.workflow.initial_stage_id, params[:options])

    if(@errors == nil)
      @result_flag.workflow_options = params[:options]
      @result_flag.current_user = current_user
      @result_flag.save
      @notice = "Result flagged!"

      #Not sure why this is necessary...
      @result.reload
      @result.result_flags.reload
    else
      @options = @result_flag.next_step_options(@flag.workflow.initial_stage_id, params[:options], current_user)
    end

  end


  def workflow_autocomplete
    @workflow = Workflowable::Workflow.find_by_id(params[:workflow_id])
    @stage = Workflowable::Stage.find_by_id(params[:stage_id])
    @action = @stage.before_actions.find_by_name(params[:action_id]) || @stage.after_actions.find_by_name(params[:action_id]) || @workflow.actions.find_by_name(params[:action_id])
    matches = @action.autocomplete(params[:field_type], params[:q])
    respond_to do |format|
      format.json { render json: matches, meta: {total: matches.count} }
    end
  end


  def action

    @notice=""
    @options=""
    @result = Result.find(params[:id])
    @result_flag = @result.result_flags.find_by_id(params[:result_flag_id])
    @next_stage = @result_flag.stage.next_steps.find_by_id(params[:stage_id])



    @errors = @result_flag.validate_actions(@next_stage.id, params[:options], current_user)
    if(@errors == nil)

      @result_flag.set_stage(@next_stage.id, params[:options], current_user )
      @result.reload
      @result.result_flags.reload
      @notice = "Stage changed!"

    else
      @options = @result_flag.next_step_options(@next_stage.id, params[:options], current_user)
    end
  end

  def tag

    params.try(:[],:tags).to_s.split(",").map do |tag_info|
      tag, color = tag_info.split("::")
      name, value = tag.split(":")


      t = Tag.where({name: name.to_s.strip, value:value.to_s.strip}).first_or_initialize
      t.color = color if color
      t.save! if t.changed?
      @result.taggings.find_or_create_by_tag_id(t.id)
    end

    redirect_to :back, notice: "Result tagged."

  end

  def add_attachment
    @result.result_attachments.create(params.require(:result_attachment).permit(:attachment))
    redirect_to :back, notice: "Attachment created."

  end

  def delete_attachment

    @result.result_attachments.where(:id=>params[:attachment_id]).delete_all
    redirect_to :back, notice: "Attachment removed."
  end

  def generate_screenshot

    if(params[:id].present?)
      load_result

      #@search.perform_search
      ScreenshotRunner.perform_async(@result.id)
      respond_to do |format|
        format.html {redirect_to result_url(@result), :notice=>"Attempting to generate a screenshot..."}
      end
    else

      ScreenshotRunner.perform_async(nil)

      respond_to do |format|
        format.html {redirect_to results_url, :notice=>"Attempting to generate screenshots..."}
      end
    end
  end

  def update_multiple
    result_ids = params[:result_ids]
    commit = params[:commit]
    if(params[:update_all_from_query] == "true")
      perform_search
      result_ids = @results.map{|r| r.id}
    end


    if(commit == "Update and Generate Screenshot")
      results_without_screenshots = Result.includes(:result_attachments).where(:id=>result_ids).where("result_attachments.id is null").references("result_attachments").order("results.created_at desc")
      ScreenshotSyncTaskRunner.perform_async(results_without_screenshots.map{|r| r.id})
    elsif(commit == "Update and Force Generate Screenshot")
      ScreenshotSyncTaskRunner.perform_async(result_ids)
    elsif(commit == "Delete Results")
      Result.delete(result_ids)
      skip_updates = true
    end

    if(!skip_updates)

      if(params[:tags].present?)
        params[:tags].to_s.split(",").each do |tag_info|
          if(params[:remove_tags] == "1")
            debugger
            tag, color = tag_info.split("::")
            name, value = tag.split(":")
            t = Tag.where({name: name.to_s.strip, value:value.to_s.strip}).first
            if(t)
              Tagging.where(:taggable_id=>result_ids, :tag_id=>t.id, :taggable_type=>"Result").delete_all
            end
            

          else
            tag, color = tag_info.split("::")
            name, value = tag.split(":")
            t = Tag.where({name: name.to_s.strip, value:value.to_s.strip}).first_or_initialize
            t.color = color if color
            t.save! if t.changed?

            columns = [:tag_id, :taggable_id, :taggable_type]
            tagging_ids = t.taggings.where(:taggable_type=>"Result").map{|tagging| tagging.taggable_id}
            tag_result_ids = result_ids.reject {|r| tagging_ids.include?(r)}

            taggables = tag_result_ids.map{|r| [t.id, r,"Result"]}
            Tagging.import(columns, taggables)

          end

          
        end
      end

      if(params[:flags].present?)
        params[:flags].split(",").each do |flag|
          f = Flag.includes(:results).find_by_id(flag)

          #Specifying stage_id and workflow_id directly because the import method will not
          columns = [:flag_id, :result_id, :stage_id, :workflow_id]
          flagged = f.results.map{|result| result.id}
          flag_result_ids = result_ids.reject {|r| flagged.include?(r)}

          flaggable = flag_result_ids.map{|r| [f.id, r, f.workflow.initial_stage_id, f.workflow_id]}

          ResultFlag.import(columns, flaggable)
        end


      end

      if(params[:status_id].present?)
        status = Status.find_by_id(params[:status_id])
        Result.update_all({:status_id => status.id}, {:id=>result_ids}) if status
      end

      if(params[:assignee_id].present?)
        user = User.find_by_id(params[:assignee_id])
        Result.update_all({:user_id => user.id}, {:id=>result_ids}) if user
      end
    end

    respond_to do |format|
      format.html {redirect_to results_url, :notice=>"Results updated."}
    end


  end

  def subscribe
    user = params[:user_id].present? ? User.find_by_id(params[:user_id]) : current_user
    if(user.subscriptions.include?(@result))
      @notice = "User already subscribed."
    else
      user.subscriptions.create(:subscribable=>@result)
      @notice = "Subscription added."
    end
  end

  def unsubscribe
    user = params[:user_id].present? ? User.find_by_id(params[:user_id]) : current_user
    user.subscriptions.where(:subscribable=>@result).delete_all
    @notice = "Subscription removed."
  end

  def update_screenshot

    if(params[:sketch_url].present?)
      sketch_url = params[:sketch_url]
      if(params[:token].present?)
        sketch_url += "?token=#{params[:token]}"
      end
      begin
        if(Rails.configuration.try(:sketchy_verify_ssl) == false || Rails.configuration.try(:sketchy_verify_ssl) == "false")
          @result.result_attachments.create(:attachment=>open(URI(sketch_url), {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}), :attachment_file_name=>File.basename(URI(sketch_url).path))
        else
          @result.result_attachments.create(:attachment=>open(URI(sketch_url)), :attachment_file_name=>File.basename(URI(sketch_url).path))
        end
      rescue Exception=>e
        Rails.logger.error "Error adding screenshot"
        Rails.logger.error e.message
        Rails.logger.error e.backtrace
      end
    end
    if(params[:scrape_url].present?)
      scrape_url = params[:scrape_url]
      if(params[:token].present?)
        scrape_url += "?token=#{params[:token]}"
      end
      if(Rails.configuration.try(:sketchy_verify_ssl) == false || Rails.configuration.try(:sketchy_verify_ssl) == "false")
        content = open(scrape_url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read
      else
        content = open(scrape_url).read
      end
      
      @result.update_attributes(:content=>content.encode('utf-8', 'binary', invalid: :replace, undef: :replace, replace: ''))
    end

    if(Rails.configuration.try(:sketchy_tag_status_code) == true || Rails.configuration.try(:sketchy_tag_status_code) == "true")
      @result.tags.delete(Tag.where(name:"Status"))
      @result.tags << Tag.where(:name=>"Status", :value=>params[:url_response_code].to_s).first_or_create
    end

    render text: "OK", layout: false

  end

  def bulk_add
    if(params[:results])
      default_status = Status.find_by_default(true)
      valid = 0
      invalid = 0
      existing = 0
      result_ids = []
      params[:results].split(/\r?\n/).each do |result|
        #r = Result.where(title: result, url: result, domain: URI.parse(result).host, status: default_status)
        r = Result.where(url: result).first_or_initialize
        if(r.new_record?)
          r.title = result
          r.domain = URI.parse(result).host
          r.status = default_status
          if(r.save)
            valid += 1
            result_ids << r.id
          else
            invalid += 1
          end
        else
          result_ids << r.id
          existing += 1
        end

        

      end
      if(result_ids.present? && params[:tags].present?)
        params[:tags].to_s.split(",").each do |tag_info|
        
          tag, color = tag_info.split("::")
          name, value = tag.split(":")
          t = Tag.where({name: name.to_s.strip, value:value.to_s.strip}).first_or_initialize
          t.color = color if color
          t.save! if t.changed?

          columns = [:tag_id, :taggable_id, :taggable_type]
          tagging_ids = t.taggings.where(:taggable_type=>"Result").map{|tagging| tagging.taggable_id}
          tag_result_ids = result_ids.reject {|r| tagging_ids.include?(r)}

          taggables = tag_result_ids.map{|r| [t.id, r,"Result"]}
          Tagging.import(columns, taggables)
        end
      end
      message = "Results added (#{valid} added, #{existing} existing, #{invalid} failures)"
      
    end

    respond_to do |format|
      format.html { redirect_to results_url, notice: message || "No results to add" }
      format.json { head :no_content }
    end


  end

  private

  def load_result
    @result = Result.includes(:result_flags=>[:flag, :stage=>[:next_steps]]).find(params[:id])

  end

  def result_params
    params.require(:result).permit(:title, :url, :status_id)
  end




  def perform_search
    @total_result_count = Result.count

    if(params[:view] == "tiles")
      session[:results_view] = "tiles" 
    elsif(params[:view] == "list")
      session[:results_view] = "list" 
    else
      session[:results_view] = session[:results_view] || "list"
    end
    
    @view = session[:results_view]



    if(params[:commit] == "Clear Search")
      session.delete(:saved_search)
      params.delete(:q)
    end

    if(params[:saved_filter_id].present?)
      @saved_filter = SavedFilter.find_by_id(params[:saved_filter_id])
      params[:q] = @saved_filter.query
    end

    if(params[:q].blank? && session[:saved_search].present?)
      params[:q] = session[:saved_search]
    end

    if(params[:q].class == String)
      params[:q] = JSON.parse(params[:q])
    end

    params[:q] ||= {}

    params[:q].reverse_merge!(:status_id_includes_closed=>"0")
    if(Status.where(:closed=>true).count == 0)
      params[:q].delete(:status_id_includes_closed)
    end

    params[:q].reject! {|k,v| v.blank? || v==[""]} if params[:q]
    session[:saved_search] = params[:q]
    session[:view] = @view

    @q = Result.perform_search(params[:q])

    if(params[:commit] == "Save")
      @saved_filter = SavedFilter.new
    end

    @results = @q.result(distinct:true)

  end

end
