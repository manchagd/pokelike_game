# frozen_string_literal: true

require 'faraday'
require 'json'
require 'fileutils'

BattleEngine.logger.info('[Seeds] Starting PokeAPI-based seed generation')

# Define local cache file path
local_data_dir = File.expand_path('../../local_data', __dir__)
json_file_path = File.join(local_data_dir, 'pokemon.json')

# rubocop:disable Style/GlobalVars
force_fetch = defined?($seed_force_fetch) && $seed_force_fetch
# rubocop:enable Style/GlobalVars

pokemon_list = []

if !force_fetch && File.exist?(json_file_path)
  BattleEngine.logger.info("[Seeds] Found local cache file at #{json_file_path}. Loading Pokémon data...")
  begin
    pokemon_list = JSON.parse(File.read(json_file_path))
    BattleEngine.logger.info("[Seeds] Loaded #{pokemon_list.size} Pokémon templates from cache.")
  rescue StandardError => e
    BattleEngine.logger.error("[Seeds] Failed to read or parse local cache file: #{e.message}. Will fetch from API instead.")
    pokemon_list = []
  end
elsif force_fetch
  BattleEngine.logger.info('[Seeds] Force fetch enabled — ignoring local cache.')
end

if pokemon_list.empty?
  BattleEngine.logger.info('[Seeds] Fetching Pokémon list from PokeAPI...')

  # Fetch a large limit to retrieve all resources in one list
  response = Faraday.get('https://pokeapi.co/api/v2/pokemon?limit=100000&offset=0')
  raise "Failed to fetch Pokemon list from PokeAPI. Status: #{response.status}" unless response.success?

  data = JSON.parse(response.body)
  results = data['results'] || []

  BattleEngine.logger.info("[Seeds] Found #{results.size} total Pokémon resources. Filtering and importing species...")

  stats_map = {
    'hp' => 'hp',
    'attack' => 'atk',
    'defense' => 'def',
    'special-attack' => 'sp_atk',
    'special-defense' => 'sp_def',
    'speed' => 'spd'
  }

  results.each do |result|
    pokemon_url = result['url']
    id_match = pokemon_url.match(%r{/pokemon/(\d+)/})
    next unless id_match

    pokemon_id = id_match[1].to_i
    # Stop when the ID reaches 10000+
    if pokemon_id >= 10_000
      BattleEngine.logger.info("[Seeds] Reached ID #{pokemon_id} (>= 10000). Stopping Pokemon fetch.")
      break
    end

    BattleEngine.logger.info("[Seeds] Fetching data for Pokemon ID #{pokemon_id}...")
    pokemon_response = Faraday.get(pokemon_url)
    unless pokemon_response.success?
      BattleEngine.logger.error("[Seeds] Failed to fetch data for Pokemon ID #{pokemon_id}. Skipping.")
      next
    end

    pokemon_data = JSON.parse(pokemon_response.body)

    # Format name nicely (e.g. mr-mime -> Mr Mime)
    name = pokemon_data['name'].split('-').map(&:capitalize).join(' ')

    # Map types and select only those in Types::LIST to satisfy validations
    types = pokemon_data['types'].map { |t| t['type']['name'].capitalize }
    types = types.select { |t| Types::LIST.include?(t) }

    # Map stats
    stats = {}
    pokemon_data['stats'].each do |s|
      stat_name = s['stat']['name']
      mapped_name = stats_map[stat_name]
      stats[mapped_name] = s['base_stat'] if mapped_name
    end

    # Fetch species data to get gender_rate
    species_url = pokemon_data.dig('species', 'url')
    gender_rate = nil
    if species_url
      species_response = Faraday.get(species_url)
      if species_response.success?
        species_data = JSON.parse(species_response.body)
        gender_rate = species_data['gender_rate']
      else
        BattleEngine.logger.error("[Seeds] Failed to fetch species data for Pokemon ID #{pokemon_id}. Skipping gender_rate.")
      end
    end

    # Extract sprites with fallback:
    #   Primary:  sprites.other.showdown.front_default / back_default
    #   Fallback: sprites.front_default                / back_default
    showdown     = pokemon_data.dig('sprites', 'other', 'showdown') || {}
    front_sprite = showdown['front_default'] || pokemon_data.dig('sprites', 'front_default')
    back_sprite  = showdown['back_default']  || pokemon_data.dig('sprites', 'back_default')

    # Extract all moves with ID <= 10000 from PokeAPI response
    # rubocop:disable Style/MultilineBlockChain
    pokeapi_move_ids = (pokemon_data['moves'] || []).filter_map do |m|
      url = m.dig('move', 'url')
      match = url&.match(%r{/move/(\d+)/})
      match ? match[1].to_i : nil
    end.select { |id| id <= 10_000 }.uniq
    # rubocop:enable Style/MultilineBlockChain

    pokemon_list << {
      'name' => name,
      'types' => types,
      'stats' => stats,
      'front_sprite' => front_sprite,
      'back_sprite' => back_sprite,
      'pokeapi_id' => pokemon_id,
      'moves' => pokeapi_move_ids,
      'gender_rate' => gender_rate
    }
  end

  # Save to local file
  begin
    FileUtils.mkdir_p(local_data_dir)
    File.write(json_file_path, JSON.pretty_generate(pokemon_list))
    BattleEngine.logger.info("[Seeds] Saved #{pokemon_list.size} Pokémon templates to cache at #{json_file_path}.")
  rescue StandardError => e
    BattleEngine.logger.error("[Seeds] Failed to write cache file: #{e.message}")
  end
end

custom_json_file_path = File.join(local_data_dir, 'pokemon_custom.json')
if File.exist?(custom_json_file_path)
  begin
    custom_pokemon = JSON.parse(File.read(custom_json_file_path))
    BattleEngine.logger.info("[Seeds] Loaded #{custom_pokemon.size} custom Pokémon templates from #{custom_json_file_path}.")
    pokemon_list.concat(custom_pokemon)
  rescue StandardError => e
    BattleEngine.logger.error("[Seeds] Failed to read or parse custom Pokémon file: #{e.message}")
  end
end

# Now perform upsert in batches of 100
BattleEngine.logger.info("[Seeds] Seeding database with #{pokemon_list.size} Pokémon templates...")

now = Time.current
pokemon_list.each_slice(100).with_index(1) do |batch, batch_number|
  db_batch = batch.map do |pkmn|
    {
      name: pkmn['name'],
      types: pkmn['types'],
      stats: pkmn['stats'],
      front_sprite: pkmn['front_sprite'],
      back_sprite: pkmn['back_sprite'],
      pokeapi_id: pkmn['pokeapi_id'],
      gender_rate: pkmn['gender_rate'],
      created_at: now,
      updated_at: now
    }
  end

  BattleEngine.logger.info("[Seeds] Inserting batch ##{batch_number} (containing #{db_batch.size} Pokemon templates)...")
  PokemonTemplate.upsert_all(db_batch, unique_by: :name)
end

BattleEngine.logger.info('[Seeds] Associating moves with Pokémon templates...')
pokemon_by_name = pokemon_list.index_by { |p| p['name'] }

PokemonTemplate.find_each do |template|
  pkmn_data = pokemon_by_name[template.name]
  next unless pkmn_data

  template.moves = Move.where(pokeapi_id: pkmn_data['moves'])
end

puts "¡Se han registrado #{PokemonTemplate.count} Pokémon con éxito!"
