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

ActiveRecord::Schema[8.0].define(version: 2025_01_24_151228) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "athletes", force: :cascade do |t|
    t.integer "espn_id"
    t.string "first_name"
    t.string "last_name"
    t.string "full_name"
    t.string "display_name"
    t.string "short_name"
    t.integer "weight"
    t.integer "height"
    t.integer "age"
    t.date "date_of_birth"
    t.integer "experience_years"
    t.integer "jersey"
    t.string "college_abbreviation", limit: 3
    t.string "headshot"
    t.boolean "is_active"
    t.bigint "position_id", null: false
    t.bigint "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["espn_id"], name: "index_athletes_on_espn_id", unique: true
    t.index ["position_id"], name: "index_athletes_on_position_id"
    t.index ["team_id"], name: "index_athletes_on_team_id"
  end

  create_table "groups", force: :cascade do |t|
    t.integer "espn_id"
    t.string "name"
    t.string "abbreviation", limit: 5
    t.boolean "is_conference"
    t.string "logo"
    t.boolean "is_active"
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["espn_id"], name: "index_groups_on_espn_id", unique: true
    t.index ["name"], name: "index_groups_on_name", unique: true
    t.index ["parent_id"], name: "index_groups_on_parent_id"
  end

  create_table "positions", force: :cascade do |t|
    t.integer "espn_id"
    t.string "abbreviation", limit: 3
    t.string "name"
    t.boolean "is_active"
    t.bigint "position_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["abbreviation"], name: "index_positions_on_abbreviation", unique: true
    t.index ["espn_id"], name: "index_positions_on_espn_id", unique: true
    t.index ["name"], name: "index_positions_on_name", unique: true
    t.index ["position_id"], name: "index_positions_on_position_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.integer "espn_id"
    t.string "slug"
    t.string "abbreviation", limit: 3
    t.string "display_name"
    t.string "short_display_name"
    t.string "name"
    t.string "nickname"
    t.string "location"
    t.string "color", limit: 6
    t.string "alternate_color", limit: 6
    t.string "logo"
    t.boolean "is_active"
    t.bigint "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["abbreviation"], name: "index_teams_on_abbreviation", unique: true
    t.index ["espn_id"], name: "index_teams_on_espn_id", unique: true
    t.index ["group_id"], name: "index_teams_on_group_id"
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((username)::text)", name: "index_users_on_lower_username", unique: true
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "athletes", "positions"
  add_foreign_key "athletes", "teams"
  add_foreign_key "groups", "groups", column: "parent_id"
  add_foreign_key "positions", "positions"
  add_foreign_key "sessions", "users"
  add_foreign_key "teams", "groups"
end
