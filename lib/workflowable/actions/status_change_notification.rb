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


class Workflowable::Actions::StatusChangeNotifcationAction < Workflowable::Actions::Action
  include ERB::Util
  include Rails.application.routes.url_helpers

  NAME="Status Change Notification Action"

  def run

    recipients = (@object.result.subscribers.map(&:subscriber_email) + @object.flag.subscribers.map(&:subscriber_email) + Array[*@object.result.try(:user).try(:email)]).uniq.compact

    if(@current_stage == nil)
      subject = "Result #{@object.result.id}: Flagged #{@workflow.name}"
      message = "<a href='#{result_url(@object.result)}'>Result #{@object.result.id}</a> has been flagged for workflow: #{@workflow.name}".html_safe
    else
      subject = "Result #{@object.result.id}: Status changed for #{@workflow.name}"
      message = "<a href='#{result_url(@object.result)}'>Result #{@object.result.id}</a> has been moved from #{@current_stage.name} to #{@next_stage.name} in the #{@workflow.name} workflow".html_safe
    end

    ::NotificationMailer.notification(
      recipients,
      subject,
      message

    ).deliver


  end

end
