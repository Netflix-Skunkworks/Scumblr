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


class ProvidersController < ApplicationController


  def options
    authorize! :options, :provider
    @search = Search.find_by_id(params[:id])
    provider = params[:provider]

    if(provider.to_s.match(/\ASearchProvider::/))
      @provider_options = provider.constantize.options if SearchProvider::Provider.subclasses.include?(provider.to_s.constantize)
    end

    respond_to do |format|
      format.js
    end

  end



end
