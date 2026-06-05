# frozen_string_literal: true

require "faraday"
require "json"

BattleEngine.logger.info("[Seeds] Starting PokeAPI-based seed generation")

# ==========================================
# 1. POPULATE POKEMON TEMPLATES FROM PokeAPI
# ==========================================

BattleEngine.logger.info("[Seeds] Fetching Pokémon list from PokeAPI...")

# Fetch a large limit to retrieve all resources in one list
response = Faraday.get("https://pokeapi.co/api/v2/pokemon?limit=100000&offset=0")
unless response.success?
  raise "Failed to fetch Pokemon list from PokeAPI. Status: #{response.status}"
end

data = JSON.parse(response.body)
results = data["results"] || []

BattleEngine.logger.info("[Seeds] Found #{results.size} total Pokémon resources. Filtering and importing species...")

stats_map = {
  "hp" => :hp,
  "attack" => :atk,
  "defense" => :def,
  "special-attack" => :sp_atk,
  "special-defense" => :sp_def,
  "speed" => :spd
}

imported_count = 0
pokemon_batch = []
now = Time.current
batch_number = 1

results.each do |result|
  if pokemon_batch.empty?
    BattleEngine.logger.info("[Seeds] Fetching items for batch ##{batch_number}...")
  end

  pokemon_url = result["url"]
  # Extract the ID from the URL (e.g. /pokemon/12/)
  id_match = pokemon_url.match(%r{/pokemon/(\d+)/})
  next unless id_match

  pokemon_id = id_match[1].to_i
  # Stop when the ID reaches 10000+
  if pokemon_id >= 10000
    BattleEngine.logger.info("[Seeds] Reached ID #{pokemon_id} (>= 10000). Stopping Pokemon import.")
    break
  end

  pokemon_response = Faraday.get(pokemon_url)
  unless pokemon_response.success?
    BattleEngine.logger.error("[Seeds] Failed to fetch data for Pokemon ID #{pokemon_id}. Skipping.")
    next
  end

  pokemon_data = JSON.parse(pokemon_response.body)
  
  # Format name nicely (e.g. mr-mime -> Mr Mime)
  name = pokemon_data["name"].split("-").map(&:capitalize).join(" ")

  # Map types and select only those in Types::LIST to satisfy validations
  types = pokemon_data["types"].map { |t| t["type"]["name"].capitalize }
  types = types.select { |t| Types::LIST.include?(t) }

  # Map stats
  stats = {}
  pokemon_data["stats"].each do |s|
    stat_name = s["stat"]["name"]
    mapped_name = stats_map[stat_name]
    stats[mapped_name] = s["base_stat"] if mapped_name
  end

  pokemon_batch << {
    name: name,
    types: types,
    stats: stats,
    created_at: now,
    updated_at: now
  }

  if pokemon_batch.size >= 100
    BattleEngine.logger.info("[Seeds] Inserting batch ##{batch_number} (containing #{pokemon_batch.size} Pokemon templates)...")
    PokemonTemplate.upsert_all(pokemon_batch, unique_by: :name)
    pokemon_batch.clear
    batch_number += 1
  end

  imported_count += 1
end

if pokemon_batch.any?
  BattleEngine.logger.info("[Seeds] Inserting final batch ##{batch_number} (containing #{pokemon_batch.size} Pokemon templates)...")
  PokemonTemplate.upsert_all(pokemon_batch, unique_by: :name)
end

puts "¡Se han registrado #{PokemonTemplate.count} Pokémon con éxito!"
