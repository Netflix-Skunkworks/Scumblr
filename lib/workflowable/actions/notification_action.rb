class Workflowable::Actions::NotificationAction < Workflowable::Actions::Action
  include ERB::Util

  NAME="Notification Action"
  OPTIONS = {
    :recipients => {
      :required=>true,
      :type=>:text,
      :description=>"The recipients of the message"
    },

    :subject => {
      :required=>true,
      :type=>:string,
      :description=>"The subject of the message"
    },
    :contents => {
      :required=>true,
      :type=>:text,
      :description=>"The contents of the message"
    }
  }

  def run

    ::NotificationMailer.notification(@options[:recipients][:value], @options[:subject][:value], @options[:contents][:value]).deliver

    # comment = ::Comment.build_from( @object.result, @user.id, @options[:message][:value])
    # comment.save
    #ses = AWS::SimpleEmailService.new
    #ses.send_email(:subject=>"Test",:from=>"scumblr@saasmail.netflix.com",:to=>"ahoernecke@netflix.com",:body_text=>"Testing123!!!!!!", :body_html=>"<b>Hi!</b>")

  end

end
