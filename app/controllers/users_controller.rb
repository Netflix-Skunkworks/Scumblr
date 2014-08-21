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



class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_admin]
  authorize_resource

  # GET /users
  # GET /users.json
  def index
    q = "%#{params[:q]}%"
    @users = User.where("email like ?", q).page(params[:page]).per(params[:per_page])

    respond_to do |format|
      format.json { render json: @users, meta: {total: @users.total_count} }
      format.html
    end
  end


  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.disabled = !@user.disabled
    @user.save
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully ' + (@user.disabled ? "disabled." : "enabled.") }
      format.json { head :no_content }
    end
  end

  def toggle_admin
    @user.admin = !@user.admin
    @user.save
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was updated successfully.' }
      format.json { head :no_content }
    end


  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user

    @user = current_user.try(:admin) ? User.find(params[:id]) : current_user
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :admin, :disabled)
  end
end
