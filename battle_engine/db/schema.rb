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

ActiveRecord::Schema[7.2].define(version: 2026_06_05_154146) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "battle_players", force: :cascade do |t|
    t.bigint "battle_id", null: false
    t.bigint "player_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["battle_id"], name: "index_battle_players_on_battle_id"
    t.index ["player_id"], name: "index_battle_players_on_player_id"
  end

  create_table "battles", force: :cascade do |t|
    t.string "battle_type", default: "single", null: false
    t.bigint "field_id", null: false
    t.bigint "winner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "turn", default: 0, null: false
    t.index ["field_id"], name: "index_battles_on_field_id"
    t.index ["winner_id"], name: "index_battles_on_winner_id"
  end

  create_table "fields", force: :cascade do |t|
    t.bigint "weather_id"
    t.bigint "hazard_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hazard_id"], name: "index_fields_on_hazard_id"
    t.index ["weather_id"], name: "index_fields_on_weather_id"
  end

  create_table "hazards", force: :cascade do |t|
    t.string "name", null: false
    t.jsonb "effect", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_hazards_on_name", unique: true
  end

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
    t.jsonb "meta", default: {}
    t.index ["name"], name: "index_moves_on_name", unique: true
  end

  create_table "players", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_players_on_name", unique: true
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

  create_table "pokemons", force: :cascade do |t|
    t.bigint "pokemon_template_id", null: false
    t.string "nickname"
    t.string "gender"
    t.string "nature", null: false
    t.decimal "weight", precision: 8, scale: 2, null: false
    t.jsonb "ivs", default: {}, null: false
    t.jsonb "evs", default: {}, null: false
    t.string "attacks", default: [], null: false, array: true
    t.integer "lvl", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "teratype"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "team_id", null: false
    t.index ["pokemon_template_id"], name: "index_pokemons_on_pokemon_template_id"
    t.index ["team_id"], name: "index_pokemons_on_team_id"
  end

  create_table "positions", force: :cascade do |t|
    t.integer "group", null: false
    t.string "side"
    t.bigint "pokemon_id"
    t.bigint "field_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["field_id"], name: "index_positions_on_field_id"
    t.index ["pokemon_id"], name: "index_positions_on_pokemon_id"
  end

  create_table "team_pokemons", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "pokemon_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pokemon_id"], name: "index_team_pokemons_on_pokemon_id"
    t.index ["team_id"], name: "index_team_pokemons_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "player_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_teams_on_player_id"
  end

  create_table "weathers", force: :cascade do |t|
    t.string "name", null: false
    t.integer "duration", default: 5, null: false
    t.integer "harm"
    t.jsonb "type_modifiers", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_weathers_on_name", unique: true
  end

  add_foreign_key "battle_players", "battles"
  add_foreign_key "battle_players", "players"
  add_foreign_key "battles", "fields"
  add_foreign_key "battles", "players", column: "winner_id"
  add_foreign_key "fields", "hazards"
  add_foreign_key "fields", "weathers"
  add_foreign_key "pokemon_template_moves", "moves"
  add_foreign_key "pokemon_template_moves", "pokemon_templates"
  add_foreign_key "pokemons", "pokemon_templates"
  add_foreign_key "pokemons", "teams"
  add_foreign_key "positions", "fields"
  add_foreign_key "positions", "pokemons"
  add_foreign_key "team_pokemons", "pokemons"
  add_foreign_key "team_pokemons", "teams"
  add_foreign_key "teams", "players"
end
