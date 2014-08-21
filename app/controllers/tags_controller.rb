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


class TagsController < ApplicationController
  authorize_resource

  def index
    q = "%#{params[:q]}%"
    @tags = Tag.where("lower(name) like lower(?)", q).page(params[:page]).per(params[:per_page])

    respond_to do |format|
      format.json { render json: @tags, meta: {total: @tags.total_count} }
    end
  end



end
