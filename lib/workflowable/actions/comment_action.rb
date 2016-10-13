class Workflowable::Actions::CommentAction < Workflowable::Actions::Action
  include ERB::Util

  NAME="Comment Action"
  OPTIONS = {
    :message => {
      :required=>true,
      :type=>:text,
      :description=>"The contents of the message"
    }
  }

  def run

    comment = ::Comment.build_from( @object.result, @user.id, @options[:message][:value])
    comment.save

  end

end