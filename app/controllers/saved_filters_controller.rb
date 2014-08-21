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


class SavedFiltersController < ApplicationController
  before_filter :set_header
  before_filter :load_saved_filter, only: [:show, :edit, :update, :destroy, :add, :remove]
  authorize_resource


  def index
    @saved_filters = current_user.saved_filters
    @added_public_saved_filters = current_user.added_saved_filters
    @public_saved_filters = SavedFilter.where(:public=>true).where.not(:user_id=>current_user.id).where.not(:id=>@added_public_saved_filters)


  end

  def create
    @saved_filter = SavedFilter.new(saved_filter_params)
    @saved_filter.user_id = current_user.id
    @saved_filter.query = params[:q]

    respond_to do |format|
      if @saved_filter.save
        format.html { redirect_to results_path, notice: 'Filter was successfully created.' }
        #format.json { render json: @saved_filter, status: :created, location: @saved_filter }
      else
        format.html { redirect_to results_path, notice: 'Could not save filter.' }
        #format.json { render json: @saved_filter.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    if(@saved_filter.user_id == current_user.id)
      @q = Result.includes(:tags,:status, :search_results).search(@saved_filter.query)
    else
      redirect_to saved_filters_path, notice: 'Could not edit filter.'
      return
    end
  end

  def update
    if(@saved_filter.user_id == current_user.id)

      @saved_filter.query = params[:q]
      respond_to do |format|
        if @saved_filter.update_attributes(saved_filter_params)
          format.html { redirect_to saved_filters_path, notice: 'Filter was successfully updated.' }
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
      redirect_to saved_filters_path, notice: 'Filter added.'
    else
      redirect_to saved_filters_path, notice: 'Could not add filter.'
    end
  end

  def remove
    current_user.added_saved_filters.delete(@saved_filter)
    redirect_to saved_filters_path, notice: 'Filter removed.'

  end



  def destroy
    if(@saved_filter.user_id == current_user.id)
      @saved_filter.destroy

      respond_to do |format|
        format.html { redirect_to saved_filters_url }
        format.json { head :no_content }
      end

    else
      redirect_to saved_filters_path, notice: 'Could not destroy filter.'
    end


  end


  private

  def saved_filter_params
    params.require(:saved_filter).permit(:public, :name, :subscriber_list)
  end

  def load_saved_filter
    @saved_filter = SavedFilter.find(params[:id])
  end

  def set_header
    @header_title = "Saved Filters"
  end




end
