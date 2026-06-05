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

results.each do |result|
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

  # Progress log
  if imported_count % 50 == 0
    BattleEngine.logger.info("[Seeds] Importing Pokemon ##{pokemon_id} (Fetched: #{imported_count})...")
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

  # Register Pokemon template
  PokemonTemplate.find_or_create_by(name: name) do |pk|
    pk.types = types
    pk.stats = stats
  end

  imported_count += 1
end

puts "¡Se han registrado #{PokemonTemplate.count} Pokémon con éxito!"

# ==========================================
# 2. POPULATE MOVES (Original static seeding)
# ==========================================

moves_list = [
  {
    name: "Tackle",
    type: "Normal",
    secondary_type: nil,
    category: "Physical",
    pp: 35,
    power: 40,
    priority: 0,
    accuracy: 100
  },
  {
    name: "Flamethrower",
    type: "Fire",
    secondary_type: nil,
    category: "Special",
    pp: 15,
    power: 90,
    priority: 0,
    accuracy: 100
  },
  {
    name: "Thunder Wave",
    type: "Electric",
    secondary_type: nil,
    category: "Status",
    pp: 20,
    power: nil, # Los movimientos de estado no suelen tener poder base
    priority: 0,
    accuracy: 90
  },
  {
    name: "Quick Attack",
    type: "Normal",
    secondary_type: nil,
    category: "Physical",
    pp: 30,
    power: 40,
    priority: 1, # Este ataque tiene prioridad alta
    accuracy: 100
  },
  {
    name: "Flying Press",
    type: "Fighting",
    secondary_type: "Flying", # Este es el único movimiento que maneja dos tipos simultáneos
    category: "Physical",
    pp: 10,
    power: 100,
    priority: 0,
    accuracy: 95
  }
]

# Método para poblar la base de datos evitando duplicados
moves_list.each do |move_data|
  Move.find_or_create_by!(name: move_data[:name]) do |m|
    m.type           = move_data[:type]
    m.secondary_type = move_data[:secondary_type]
    m.category       = move_data[:category]
    m.pp             = move_data[:pp]
    m.power          = move_data[:power]
    m.priority       = move_data[:priority]
    m.accuracy       = move_data[:accuracy]
  end
end

puts "¡Se han registrado #{Move.count} movimientos correctamente!"
