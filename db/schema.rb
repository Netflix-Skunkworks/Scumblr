# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150803212059) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "comments", force: true do |t|
    t.integer  "commentable_id",   default: 0
    t.string   "commentable_type", default: ""
    t.string   "title",            default: ""
    t.text     "body"
    t.string   "subject",          default: ""
    t.integer  "user_id",          default: 0,  null: false
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "comments", ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "event_changes", force: true do |t|
    t.integer  "event_id"
    t.string   "field"
    t.text     "new_value"
    t.text     "old_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "old_value_key"
    t.integer  "new_value_key"
    t.string   "value_class"
  end

  add_index "event_changes", ["event_id"], name: "index_event_changes_on_event_id", using: :btree

  create_table "events", force: true do |t|
    t.string   "action"
    t.string   "source"
    t.text     "details"
    t.datetime "date"
    t.integer  "user_id"
    t.integer  "eventable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "eventable_type"
  end

  add_index "events", ["eventable_id"], name: "index_events_on_eventable_id", using: :btree
  add_index "events", ["user_id"], name: "index_events_on_user_id", using: :btree

  create_table "flags", force: true do |t|
    t.string   "name"
    t.string   "color"
    t.integer  "workflow_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "result_attachments", force: true do |t|
    t.integer  "result_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.string   "attachment_fingerprint"
  end

  add_index "result_attachments", ["result_id"], name: "index_result_attachments_on_result_id", using: :btree

  create_table "result_flags", force: true do |t|
    t.integer  "stage_id"
    t.integer  "workflow_id"
    t.integer  "flag_id"
    t.integer  "result_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "result_flags", ["flag_id"], name: "index_result_flags_on_flag_id", using: :btree
  add_index "result_flags", ["result_id"], name: "index_result_flags_on_result_id", using: :btree

# Could not dump table "results" because of following StandardError
#   Unknown type 'jsonb' for column 'metadata'

  create_table "saved_filters", force: true do |t|
    t.string   "name"
    t.text     "query"
    t.integer  "user_id"
    t.boolean  "public"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "saved_filter_type"
  end

  add_index "saved_filters", ["user_id"], name: "index_saved_filters_on_user_id", using: :btree

  create_table "statuses", force: true do |t|
    t.string   "name"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.boolean  "closed"
    t.boolean  "is_invalid"
    t.boolean  "default",    default: false
  end

  create_table "subscribers", force: true do |t|
    t.integer  "subscribable_id"
    t.string   "subscribable_type"
    t.string   "email"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "summaries", force: true do |t|
    t.integer  "summarizable_id"
    t.string   "summarizable_type"
    t.datetime "timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", force: true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "taggable_type"
  end

  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
  add_index "taggings", ["taggable_id"], name: "index_taggings_on_result_id", using: :btree

  create_table "tags", force: true do |t|
    t.string   "name"
    t.string   "color"
    t.string   "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "task_results", force: true do |t|
    t.integer  "result_id"
    t.integer  "task_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "task_results", ["result_id"], name: "index_task_results_on_result_id", using: :btree
  add_index "task_results", ["task_id", "result_id"], name: "unique_search_results", unique: true, using: :btree
  add_index "task_results", ["task_id"], name: "index_task_results_on_task_id", using: :btree

# Could not dump table "tasks" because of following StandardError
#   Unknown type 'jsonb' for column 'metadata'

  create_table "user_saved_filters", force: true do |t|
    t.integer  "user_id"
    t.integer  "saved_filter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_saved_filters", ["saved_filter_id"], name: "index_user_saved_filters_on_saved_filter_id", using: :btree
  add_index "user_saved_filters", ["user_id"], name: "index_user_saved_filters_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",              default: "",    null: false
    t.string   "encrypted_password", default: "",    null: false
    t.integer  "sign_in_count",      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "provider"
    t.string   "uid"
    t.boolean  "admin",              default: false
    t.boolean  "disabled",           default: false
    t.string   "first_name"
    t.string   "last_name"
    t.text     "thumbnail"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

  create_table "workflowable_actions", force: true do |t|
    t.string   "name"
    t.text     "options"
    t.string   "action_plugin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
  end

  create_table "workflowable_stage_actions", force: true do |t|
    t.integer  "stage_id"
    t.integer  "action_id"
    t.string   "event"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "workflowable_stage_actions", ["action_id"], name: "index_workflowable_stage_actions_on_action_id", using: :btree
  add_index "workflowable_stage_actions", ["stage_id"], name: "index_workflowable_stage_actions_on_stage_id", using: :btree

  create_table "workflowable_stage_next_steps", force: true do |t|
    t.integer  "current_stage_id"
    t.integer  "next_stage_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "workflowable_stages", force: true do |t|
    t.string   "name"
    t.integer  "workflow_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "workflowable_stages", ["workflow_id"], name: "index_workflowable_stages_on_workflow_id", using: :btree

  create_table "workflowable_workflow_actions", force: true do |t|
    t.integer  "workflow_id"
    t.integer  "action_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "workflowable_workflow_actions", ["action_id"], name: "index_workflowable_workflow_actions_on_action_id", using: :btree
  add_index "workflowable_workflow_actions", ["workflow_id"], name: "index_workflowable_workflow_actions_on_workflow_id", using: :btree

  create_table "workflowable_workflows", force: true do |t|
    t.string   "name"
    t.integer  "initial_stage_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
