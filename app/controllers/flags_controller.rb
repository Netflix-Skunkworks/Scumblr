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


class FlagsController < ApplicationController
  before_action :set_flag, only: [:show, :edit, :update, :destroy]
  authorize_resource

  # GET /flags
  # GET /flags.json
  def index
    if(params[:q])
      @flags = Flag.where("lower(name) like lower(?)", "%#{params[:q]}%").page(params[:page]).per(params[:per_page])
    else
      @flags = Flag.all.page(params[:page]).per(params[:per_page])
    end

    respond_to do |format|
      format.html
      format.json { render json: @flags, meta: {total: @flags.total_count} }
    end
  end


  # GET /flags/1
  # GET /flags/1.json
  def show
  end

  # GET /flags/new
  def new
    @flag = Flag.new
  end

  # GET /flags/1/edit
  def edit
  end

  # POST /flags
  # POST /flags.json
  def create
    @flag = Flag.new(flag_params)

    respond_to do |format|
      if @flag.save
        format.html { redirect_to @flag, notice: 'Flag was successfully created.' }
        format.json { render action: 'show', status: :created, location: @flag }
      else
        format.html { render action: 'new' }
        format.json { render json: @flag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /flags/1
  # PATCH/PUT /flags/1.json
  def update
    respond_to do |format|
      if @flag.update(flag_params)
        format.html { redirect_to @flag, notice: 'Flag was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @flag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /flags/1
  # DELETE /flags/1.json
  def destroy
    @flag.destroy
    respond_to do |format|
      format.html { redirect_to flags_url }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_flag
    @flag = Flag.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def flag_params
    params.require(:flag).permit(:name, :color, :workflow_id, :description, :subscriber_list)
  end
end
