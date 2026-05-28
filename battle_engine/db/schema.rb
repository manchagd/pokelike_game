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

ActiveRecord::Schema[7.2].define(version: 2026_05_28_232503) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "moves", force: :cascade do |t|
    t.string "name", null: false
    t.string "type", null: false
    t.string "secondary_type"
    t.string "category", null: false
    t.integer "pp", null: false
    t.integer "power"
    t.integer "priority", default: 0, null: false
    t.integer "accuracy", default: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_moves_on_name", unique: true
  end

  create_table "pokemon_template_moves", force: :cascade do |t|
    t.bigint "pokemon_template_id", null: false
    t.bigint "move_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["move_id"], name: "index_pokemon_template_moves_on_move_id"
    t.index ["pokemon_template_id"], name: "index_pokemon_template_moves_on_pokemon_template_id"
  end

  create_table "pokemon_templates", force: :cascade do |t|
    t.string "name", null: false
    t.string "types", default: [], array: true
    t.jsonb "stats", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_pokemon_templates_on_name", unique: true
  end

  add_foreign_key "pokemon_template_moves", "moves"
  add_foreign_key "pokemon_template_moves", "pokemon_templates"
end
