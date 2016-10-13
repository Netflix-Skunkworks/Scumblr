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


class SavedFiltersController < ApplicationController
  before_filter :set_header
  before_filter :load_saved_filter, only: [:show, :edit, :update, :destroy, :add, :remove]
  authorize_resource


  def index
    if(params[:saved_filter_type])
      @saved_filters = current_user.saved_filters.where(saved_filter_type: params[:saved_filter_type])
      @added_public_saved_filters = current_user.added_saved_filters.where(saved_filter_type: params[:saved_filter_type])
      @public_saved_filters = SavedFilter.where(:public=>true).where.not(:user_id=>current_user.id).where(saved_filter_type: params[:saved_filter_type]).where.not(:id=>@added_public_saved_filters)
    else
      @saved_filters = current_user.saved_filters
      @added_public_saved_filters = current_user.added_saved_filters
      @public_saved_filters = SavedFilter.where(:public=>true).where.not(:user_id=>current_user.id).where.not(:id=>@added_public_saved_filters)
    end
  end

  def create
    @saved_filter = SavedFilter.new(saved_filter_params)
    @saved_filter.user_id = current_user.id
    @saved_filter.query = params[:q]
    if(@saved_filter.store_index_columns == true)
      @saved_filter.index_columns = parse_columns(params[:columns]).to_json
    else
      @saved_filter.index_columns = "null"
    end

    respond_to do |format|
      if @saved_filter.save
        format.html { redirect_to saved_filters_path(saved_filter_type: @saved_filter.saved_filter_type), notice: 'Filter was successfully created.' }
        #format.json { render json: @saved_filter, status: :created, location: @saved_filter }
      else
        format.html { redirect_to saved_filters_path(saved_filter_type: @saved_filter.saved_filter_type), notice: 'Could not save filter: ' + @saved_filter.errors.full_messages.join(", ")  }
        #format.json { render json: @saved_filter.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit

    begin
      stored_columns = JSON.parse(@saved_filter.index_columns)
    rescue
      stored_columns = nil
    end

    if(stored_columns && @saved_filter.store_index_columns)
      @index_columns = stored_columns
    end
    
    @index_columns ||= session[:results_index_columns] || Rails.configuration.try(:results_index_columns) || [:screenshot,:name, :status_id, :created_at, :updated_at]
    if(@saved_filter.user_id == current_user.id)
      @q, @results = @saved_filter.saved_filter_type.constantize.perform_search(@saved_filter.query)
      @raw_query = @saved_filter.query

    else
      redirect_to root_path, notice: 'Could not edit filter.'
      return
    end
  end

  def update
    
    if(@saved_filter.user_id == current_user.id)

      
      respond_to do |format|
        @saved_filter.assign_attributes(saved_filter_params)
        @saved_filter.query = params[:q]
        if(@saved_filter.store_index_columns == true)
          @saved_filter.index_columns = parse_columns(params[:columns]).to_json
        else
          @saved_filter.index_columns = nil
        end

        
        if(@saved_filter.save)
          format.html { redirect_to saved_filters_path(saved_filter_type: @saved_filter.saved_filter_type), notice: 'Filter was successfully updated.' }
          #format.json { head :no_content }
        else
          format.html { render action: "edit" }

        end
      end
    else
      redirect_to saved_filters_path, notice: 'Could not update filter.'
      return
    end

  end

  def add
    if(@saved_filter.user_id != current_user.id && @saved_filter.public == true && !(current_user.user_saved_filters.include?(@saved_filter)))
      current_user.added_saved_filters << @saved_filter
      redirect_to saved_filters_path(saved_filter_type: params[:saved_filter_type]), notice: 'Filter added.'
    else
      redirect_to root_path, notice: 'Could not add filter.'
    end
  end

  def remove
    current_user.added_saved_filters.delete(@saved_filter)
    redirect_to saved_filters_path(saved_filter_type:params[:saved_filter_type]), notice: 'Filter removed.'

  end



  def destroy
    if(@saved_filter.user_id == current_user.id)
      saved_filter_type = @saved_filter.saved_filter_type
      @saved_filter.destroy


      respond_to do |format|
        format.html { redirect_to saved_filters_path(saved_filter_type: saved_filter_type) }
        format.json { head :no_content }
      end

    else
      redirect_to root_path, notice: 'Could not destroy filter.'
    end


  end


  private

  def parse_columns(columns)
    columns = columns.try(:reject) {|k,v| v=="0"}
    stored_columns = []

    metadata_fields = columns.try(:[],:metadata_fields)
    built_in_fields = columns.try(:[],:built_in)

    built_in_fields.to_s.split(",").reject{|f| !Result.valid_column_names.include?(f.to_s)}.each do |v|
      stored_columns << v.to_sym
    end

    metadata_fields.to_s.split(",").each do |field|
      stored_columns << ("metadata:" + field.to_s)
    end

    stored_columns
  end

  def saved_filter_params
    params.require(:saved_filter).permit(:public, :name, :subscriber_list, :saved_filter_type, :store_index_columns)
  end

  def load_saved_filter

    @saved_filter = SavedFilter.find(params[:id])
    if(!params[:q])
      params[:q] = @saved_filter.query
      end
  end

  def set_header
    @header_title = "Saved Filters"
  end




end
