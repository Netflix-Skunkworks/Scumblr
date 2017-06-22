require "test_helper"
require "byebug"
class CommentTest < ActiveSupport::TestCase

  # Validations Tests
  should validate_presence_of(:body)
  should validate_presence_of(:user)

  # Association Tests
  should belong_to(:commentable)
  should belong_to(:user)

  # Class Method Tests
  test "execute comment build_from function" do
    new_comment = Comment.build_from(Result.first, 1, "foo")
    new_comment.save!
    assert_equal(1, Result.first.comment_threads.count)
  end

  # Instance Method Tests
  test "execute has_children method" do
    fixture_comment = Comment.first
    assert_equal(false, fixture_comment.has_children?)
  end

  test "execute find_commentable method" do
    assert_equal(1, Comment.find_commentable("Result", 1).id)
  end
end
