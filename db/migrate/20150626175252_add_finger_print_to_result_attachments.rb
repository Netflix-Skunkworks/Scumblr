class AddFingerPrintToResultAttachments < ActiveRecord::Migration
  def change
    add_column :result_attachments, :attachment_fingerprint, :string
  end
end
