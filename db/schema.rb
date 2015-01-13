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

ActiveRecord::Schema.define(version: 20140811050747) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "accounts", force: true do |t|
    t.integer  "user_id",     null: false
    t.string   "provider",    null: false
    t.string   "uid",         null: false
    t.hstore   "info"
    t.hstore   "credentials"
    t.hstore   "metadata"
    t.text     "auth_hash"
    t.datetime "fetched_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accounts", ["fetched_at"], name: "index_accounts_on_fetched_at", using: :btree
  add_index "accounts", ["provider", "uid"], name: "index_accounts_on_provider_and_uid", unique: true, using: :btree
  add_index "accounts", ["user_id"], name: "index_accounts_on_user_id", using: :btree

  create_table "bookmark_imports", force: true do |t|
    t.string   "bookmark_file",               null: false
    t.integer  "user_id"
    t.integer  "status",          default: 0
    t.integer  "bookmarks_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bookmark_imports", ["user_id"], name: "index_bookmark_imports_on_user_id", using: :btree

  create_table "clicks", force: true do |t|
    t.integer  "link_id",    null: false
    t.integer  "user_id"
    t.datetime "clicked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "clicks", ["link_id"], name: "index_clicks_on_link_id", using: :btree
  add_index "clicks", ["user_id"], name: "index_clicks_on_user_id", using: :btree

  create_table "email_deliveries", force: true do |t|
    t.integer  "email_stat_id", null: false
    t.string   "tracking_code", null: false
    t.string   "subject"
    t.datetime "read_at"
    t.datetime "clicked_at"
    t.datetime "created_at"
  end

  add_index "email_deliveries", ["email_stat_id"], name: "index_email_deliveries_on_email_stat_id", using: :btree
  add_index "email_deliveries", ["tracking_code"], name: "index_email_deliveries_on_tracking_code", unique: true, using: :btree

  create_table "email_stats", force: true do |t|
    t.string   "email",      null: false
    t.string   "tag"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_stats", ["email"], name: "index_email_stats_on_email", unique: true, using: :btree
  add_index "email_stats", ["tag"], name: "index_email_stats_on_tag", unique: true, using: :btree

  create_table "feedbacks", force: true do |t|
    t.string   "email",       null: false
    t.string   "subject",     null: false
    t.text     "description"
    t.text     "note"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "folder_invitations", force: true do |t|
    t.integer  "user_id",                  null: false
    t.integer  "folder_id",                null: false
    t.string   "email"
    t.text     "message"
    t.integer  "status",       default: 0
    t.string   "code",                     null: false
    t.integer  "recipient_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "folder_invitations", ["code"], name: "index_folder_invitations_on_code", unique: true, using: :btree
  add_index "folder_invitations", ["folder_id"], name: "index_folder_invitations_on_folder_id", using: :btree
  add_index "folder_invitations", ["recipient_id"], name: "index_folder_invitations_on_recipient_id", using: :btree
  add_index "folder_invitations", ["status"], name: "index_folder_invitations_on_status", using: :btree
  add_index "folder_invitations", ["user_id"], name: "index_folder_invitations_on_user_id", using: :btree

  create_table "folders", force: true do |t|
    t.string   "name",                         null: false
    t.integer  "user_id",                      null: false
    t.integer  "links_count",      default: 0
    t.integer  "parent_folder_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sharings_count",   default: 0
  end

  add_index "folders", ["name", "user_id"], name: "index_folders_on_name_and_user_id", unique: true, using: :btree
  add_index "folders", ["parent_folder_id"], name: "index_folders_on_parent_folder_id", using: :btree
  add_index "folders", ["user_id"], name: "index_folders_on_user_id", using: :btree

  create_table "friendly_id_slugs", force: true do |t|
    t.string   "slug",                      null: false
    t.integer  "sluggable_id",              null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope"
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "links", force: true do |t|
    t.string   "name",       limit: 1024
    t.string   "keywords",                default: [],              array: true
    t.text     "note"
    t.string   "source",                               null: false
    t.string   "source_id"
    t.string   "source_uid"
    t.datetime "saved_at",                             null: false
    t.integer  "saved_by",                default: 0
    t.integer  "user_id",                              null: false
    t.integer  "page_id",                              null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "folder_id"
  end

  add_index "links", ["folder_id"], name: "index_links_on_folder_id", using: :btree
  add_index "links", ["page_id"], name: "index_links_on_page_id", using: :btree
  add_index "links", ["saved_by"], name: "index_links_on_saved_by", using: :btree
  add_index "links", ["user_id", "page_id"], name: "index_links_on_user_id_and_page_id", unique: true, using: :btree
  add_index "links", ["user_id"], name: "index_links_on_user_id", using: :btree

  create_table "pages", force: true do |t|
    t.string   "url",          limit: 1024,             null: false
    t.string   "image_url",    limit: 1024
    t.string   "title",        limit: 1024
    t.string   "site_name"
    t.text     "description"
    t.text     "html"
    t.text     "content"
    t.text     "content_html"
    t.string   "content_type"
    t.text     "fetch_error"
    t.datetime "fetched_at"
    t.integer  "links_count",               default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pages", ["url"], name: "index_pages_on_url", unique: true, using: :btree

  create_table "sharings", force: true do |t|
    t.integer  "creator_id", null: false
    t.integer  "folder_id",  null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sharings", ["creator_id"], name: "index_sharings_on_creator_id", using: :btree
  add_index "sharings", ["folder_id", "user_id"], name: "index_sharings_on_folder_id_and_user_id", unique: true, using: :btree
  add_index "sharings", ["folder_id"], name: "index_sharings_on_folder_id", using: :btree
  add_index "sharings", ["user_id"], name: "index_sharings_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                              null: false
    t.string   "encrypted_password"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "username"
    t.string   "remember_token"
    t.string   "time_zone"
    t.hstore   "metadata"
    t.string   "image_url"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["remember_token"], name: "index_users_on_remember_token", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

end
