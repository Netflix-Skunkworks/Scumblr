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

ActiveRecord::Schema.define(version: 20140922200438) do

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
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type"
  add_index "comments", ["user_id"], name: "index_comments_on_user_id"

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
  end

  add_index "result_attachments", ["result_id"], name: "index_result_attachments_on_result_id"

  create_table "result_flags", force: true do |t|
    t.integer  "stage_id"
    t.integer  "workflow_id"
    t.integer  "flag_id"
    t.integer  "result_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "result_flags", ["flag_id"], name: "index_result_flags_on_flag_id"
  add_index "result_flags", ["result_id"], name: "index_result_flags_on_result_id"

  create_table "results", force: true do |t|
    t.string   "title"
    t.string   "url"
    t.integer  "status_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "domain"
    t.integer  "user_id"
    t.text     "content"
    t.text     "metadata"
  end

  add_index "results", ["status_id"], name: "index_results_on_status_id"
  add_index "results", ["url"], name: "unique_results", unique: true

  create_table "saved_filters", force: true do |t|
    t.string   "name"
    t.text     "query"
    t.integer  "user_id"
    t.boolean  "public"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "saved_filters", ["user_id"], name: "index_saved_filters_on_user_id"

  create_table "search_results", force: true do |t|
    t.integer  "result_id"
    t.integer  "search_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "search_results", ["result_id"], name: "index_search_results_on_result_id"
  add_index "search_results", ["search_id", "result_id"], name: "unique_search_results", unique: true
  add_index "search_results", ["search_id"], name: "index_search_results_on_search_id"

  create_table "searches", force: true do |t|
    t.string   "provider"
    t.text     "options"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "query"
  end

  create_table "statuses", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "taggable_type"
  end

  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id"], name: "index_taggings_on_taggable_id"

  create_table "tags", force: true do |t|
    t.string   "name"
    t.string   "color"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_saved_filters", force: true do |t|
    t.integer  "user_id"
    t.integer  "saved_filter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_saved_filters", ["saved_filter_id"], name: "index_user_saved_filters_on_saved_filter_id"
  add_index "user_saved_filters", ["user_id"], name: "index_user_saved_filters_on_user_id"

  create_table "users", force: true do |t|
    t.string   "email",              default: "",    null: false
    t.string   "encrypted_password", default: "",    null: false
    t.integer  "sign_in_count",      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider"
    t.string   "uid"
    t.boolean  "admin",              default: false
    t.boolean  "disabled"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true

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
    t.integer  "position"
  end

  add_index "workflowable_stage_actions", ["action_id"], name: "index_workflowable_stage_actions_on_action_id"
  add_index "workflowable_stage_actions", ["stage_id"], name: "index_workflowable_stage_actions_on_stage_id"

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

  add_index "workflowable_stages", ["workflow_id"], name: "index_workflowable_stages_on_workflow_id"

  create_table "workflowable_workflow_actions", force: true do |t|
    t.integer  "workflow_id"
    t.integer  "action_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "workflowable_workflow_actions", ["action_id"], name: "index_workflowable_workflow_actions_on_action_id"
  add_index "workflowable_workflow_actions", ["workflow_id"], name: "index_workflowable_workflow_actions_on_workflow_id"

  create_table "workflowable_workflows", force: true do |t|
    t.string   "name"
    t.integer  "initial_stage_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
