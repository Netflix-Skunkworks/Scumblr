require "test_helper"

class ResultAttachmentTest < ActiveSupport::TestCase
  # Association Tests
  should belong_to(:result)

  # Load Fixtured Result Attachment
  fixture_attachment = ResultAttachment.first

  # Paperclip Tests
  should have_attached_file(:attachment)
  should validate_attachment_content_type(:attachment).allowing('image/png', 'image/jpeg', 'image/pjpeg', 'image/gif','image/x-png','text/plain').rejecting('anything/else')

  # Instance Method Tests
  test "should execute get_expiring_url" do
    assert_equal("/system/result_attachments/attachments/000/000/001/original/test.png", fixture_attachment.get_expiring_url.gsub(/\?.*/, ''))
  end
  test "should execute pretty_filesize" do
    test_attachment = ResultAttachment.new
    test_attachment.attachment = File.new('test/fixtures/files/happy.jpg')
    assert_equal("206.85 KiB", test_attachment.pretty_filesize)
  end
end
