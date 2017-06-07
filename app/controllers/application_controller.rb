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


class ApplicationController < ActionController::Base
  protect_from_forgery


  check_authorization :unless => :devise_controller?
  # rescue_from CanCan::AccessDenied do |exception|
  #   redirect_to root_url, :alert => exception.message
  # end


  rescue_from Exception, :with => :handler_exception

  before_filter :authenticate_user!
  before_filter :require_enabled
  
  force_ssl if: :ssl_configured?

  def require_enabled
    if(current_user && current_user.disabled ==true)
      reset_session
      redirect_to new_user_session_path, notice: "Your account is disabled."

    end
  end

  def ssl_configured?
    !(Rails.env.development? || Rails.env.profile? || Rails.env.test? || Rails.env.dirtylaundrydev? )
  end

  def handler_exception(exception)
    if request.xhr? then
      error_id = SecureRandom.uuid

      message = "Error (#{error_id}): #{exception.class.to_s} "
      message += " in #{request.parameters['controller'].camelize}Controller" if request.parameters['controller']
      message += "##{request.parameters['action']}" if request.parameters['action']
      message += "\n#{exception.message}"
      message += "\n\nFull Trace:\n#{exception.backtrace.join("\n")}"
      message += "\n\nRequest:\n#{params.inspect.gsub(',', ",\n")}"
      # log the error
      logger.fatal "#{message}"
      message = "An error has occurred. You can reference #{error_id} for this error." if Rails.env.production?
      respond_to do |wants|

        @notice = message
        wants.js { render partial: "shared/ajax_error", :status => :internal_server_error  }
      end
    else
      # not an ajax request, use the default handling;
      # actionpack-2.2.2/lib/action_controller/rescue.rb
      raise exception
    end
    return # don't risk DoubleRenderError
  end

  private

  def get_paginated_results(object, symbol, options)
    results = object.send(symbol).includes(options[:includes]).page(params[:page] || 1).per(params[:per_page] || 25)
    results = results.order({options[:order].to_sym => options[:direction].blank? ? :asc : options[:direction].to_sym}) if(options[:order].present?)

    instance_variable_set("@#{symbol}_count",object.send(symbol).count)
    instance_variable_set("@#{symbol}_paginated", results)
  end

end
