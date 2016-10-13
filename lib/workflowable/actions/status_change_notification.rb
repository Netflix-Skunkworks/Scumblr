class Workflowable::Actions::StatusChangeNotifcationAction < Workflowable::Actions::Action
  include ERB::Util
  include Rails.application.routes.url_helpers

  NAME="Status Change Notification Action"

  def run
    #@options = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }


    recipients = (@object.result.subscribers.map(&:subscriber_email) + @object.flag.subscribers.map(&:subscriber_email) + Array[*@object.result.try(:user).try(:email)]).uniq.compact 

    puts "***Recipients: #{recipients.inspect}"

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