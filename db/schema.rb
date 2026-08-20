# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_09_131236) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "cv_section_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "category"
    t.string "company"
    t.text "content"
    t.datetime "created_at", null: false
    t.boolean "current", default: false, null: false
    t.uuid "cv_section_id", null: false
    t.string "date"
    t.string "degree"
    t.text "description"
    t.string "email"
    t.string "end_date"
    t.string "full_name"
    t.string "github"
    t.string "gpa"
    t.string "honors"
    t.string "issuer"
    t.string "job_title"
    t.string "language"
    t.string "link"
    t.string "linkedin"
    t.string "location"
    t.string "name"
    t.string "organization"
    t.string "other_link"
    t.string "phone"
    t.integer "position", default: 0, null: false
    t.string "proficiency"
    t.string "publisher"
    t.string "relationship"
    t.string "role"
    t.string "school"
    t.text "skills_text"
    t.string "start_date"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["cv_section_id", "position"], name: "index_cv_section_items_on_cv_section_id_and_position"
    t.index ["cv_section_id"], name: "index_cv_section_items_on_cv_section_id"
  end

  create_table "cv_sections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "cv_id", null: false
    t.integer "position", default: 0, null: false
    t.string "section_type", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["cv_id", "position"], name: "index_cv_sections_on_cv_id_and_position"
    t.index ["cv_id"], name: "index_cv_sections_on_cv_id"
  end

  create_table "cvs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "schema_version", default: 1, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_cvs_on_user_id"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "jti", null: false
    t.string "name", null: false
    t.string "provider"
    t.integer "role", default: 0, null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "cv_section_items", "cv_sections"
  add_foreign_key "cv_sections", "cvs"
  add_foreign_key "cvs", "users"
  add_foreign_key "refresh_tokens", "users"
end
