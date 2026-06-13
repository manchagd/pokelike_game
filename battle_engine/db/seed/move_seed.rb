# frozen_string_literal: true

require 'faraday'
require 'json'
require 'fileutils'

BattleEngine.logger.info('[Seeds] Starting PokeAPI-based move seed generation')

# Define local cache file path
local_data_dir = File.expand_path('../../local_data', __dir__)
json_file_path = File.join(local_data_dir, 'moves.json')

# rubocop:disable Style/GlobalVars
force_fetch = defined?($seed_force_fetch) && $seed_force_fetch
# rubocop:enable Style/GlobalVars

# Faraday client with explicit timeouts to survive slow PokeAPI responses
# during bulk fetching (~900 sequential requests).
def pokeapi_client
  Faraday.new do |f|
    f.options.timeout      = 30  # read timeout (seconds)
    f.options.open_timeout = 10  # connection timeout (seconds)
  end
end

# Fetch a URL with up to max_retries attempts and exponential backoff.
# Returns the response or nil if all attempts fail.
def fetch_with_retry(url, logger, max_retries: 3)
  attempts = 0
  begin
    attempts += 1
    pokeapi_client.get(url)
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    if attempts <= max_retries
      wait = 2**attempts
      logger.warn("[Seeds] Timeout fetching #{url} (attempt #{attempts}/#{max_retries}). Retrying in #{wait}s...")
      sleep(wait)
      retry
    else
      logger.error("[Seeds] Gave up fetching #{url} after #{max_retries} attempts: #{e.message}")
      nil
    end
  end
end

moves_list = []

if !force_fetch && File.exist?(json_file_path)
  BattleEngine.logger.info("[Seeds] Found local cache at #{json_file_path}. Loading moves data...")
  begin
    moves_list = JSON.parse(File.read(json_file_path))
    BattleEngine.logger.info("[Seeds] Loaded #{moves_list.size} moves from cache.")
  rescue StandardError => e
    BattleEngine.logger.error("[Seeds] Failed to parse cache: #{e.message}. Will fetch from API.")
    moves_list = []
  end
elsif force_fetch
  BattleEngine.logger.info('[Seeds] Force fetch enabled — ignoring local cache.')
end

if moves_list.empty?
  BattleEngine.logger.info('[Seeds] Fetching moves list from PokeAPI...')

  response = Faraday.get('https://pokeapi.co/api/v2/move?limit=100000&offset=0')
  raise "Failed to fetch moves list from PokeAPI. Status: #{response.status}" unless response.success?

  data    = JSON.parse(response.body)
  results = data['results'] || []

  BattleEngine.logger.info("[Seeds] Found #{results.size} total move resources. Processing...")

  # Maps PokeAPI stat names to internal stat keys
  stats_map = {
    'hp' => 'hp',
    'attack' => 'atk',
    'defense' => 'def',
    'special-attack' => 'sp_atk',
    'special-defense' => 'sp_def',
    'speed' => 'spd',
    'accuracy' => 'accuracy',
    'evasion' => 'evasion'
  }

  # ID 560 is Flying Press — the only move with a secondary type
  FLYING_PRESS_ID = 560

  results.each do |result|
    move_url = result['url']
    id_match = move_url.match(%r{/move/(\d+)/})
    next unless id_match

    move_id = id_match[1].to_i

    if move_id >= 10_000
      BattleEngine.logger.info("[Seeds] Reached ID #{move_id} (>= 10000). Stopping move fetch.")
      break
    end

    BattleEngine.logger.info("[Seeds] Fetching move ID #{move_id}...")
    move_response = fetch_with_retry(move_url, BattleEngine.logger)
    if move_response.nil? || !move_response.success?
      BattleEngine.logger.error("[Seeds] Failed to fetch move ID #{move_id}. Skipping.")
      next
    end

    move_data = JSON.parse(move_response.body)

    # Format name (e.g. "swords-dance" -> "Swords Dance")
    name = move_data['name'].split('-').map(&:capitalize).join(' ')

    # Primary type
    type = move_data.dig('type', 'name')&.capitalize

    # Secondary type — only Flying Press (ID 560) has one
    secondary_type = move_id == FLYING_PRESS_ID ? 'Flying' : nil

    # Damage class → category
    category = move_data.dig('damage_class', 'name')&.capitalize

    stat_changes = (move_data['stat_changes'] || []).map do |sc|
      mapped_stat = stats_map[sc.dig('stat', 'name')] || sc.dig('stat', 'name')
      { 'stat' => mapped_stat, 'change' => sc['change'] }
    end

    raw_meta = move_data['meta']

    meta = if raw_meta
             # Stat changes array: [{ stat: "atk", change: 2 }, ...]
             {
               'ailment' => {
                 'name' => raw_meta.dig('ailment', 'name'),
                 'chance' => raw_meta['ailment_chance']
               },
               'crit_rate' => raw_meta['crit_rate'],
               'flinch_chance' => raw_meta['flinch_chance'],
               'drain' => raw_meta['drain'],
               'healing' => raw_meta['healing'],
               'max_hits' => raw_meta['max_hits'],
               'min_hits' => raw_meta['min_hits'],
               'max_turns' => raw_meta['max_turns'],
               'min_turns' => raw_meta['min_turns'],
               'stat_changes' => stat_changes
             }
           end

    # handler comes from meta.category (behavior category, separate from damage_class)
    handler = raw_meta&.dig('category', 'name')

    moves_list << {
      'name' => name,
      'type' => type,
      'secondary_type' => secondary_type,
      'category' => category,
      'handler' => handler,
      'pp' => move_data['pp'],
      'power' => move_data['power'],
      'priority' => move_data['priority'],
      'accuracy' => move_data['accuracy'],
      'meta' => meta,
      'pokeapi_id' => move_id
    }
  end

  # Save to local cache
  begin
    FileUtils.mkdir_p(local_data_dir)
    File.write(json_file_path, JSON.pretty_generate(moves_list))
    BattleEngine.logger.info("[Seeds] Saved #{moves_list.size} moves to cache at #{json_file_path}.")
  rescue StandardError => e
    BattleEngine.logger.error("[Seeds] Failed to write cache: #{e.message}")
  end
end

# Upsert to DB in batches of 100
BattleEngine.logger.info("[Seeds] Seeding database with #{moves_list.size} moves...")

now = Time.current
moves_list.each_slice(100).with_index(1) do |batch, batch_number|
  db_batch = batch.map do |mv|
    {
      name: mv['name'],
      type: mv['type'],
      secondary_type: mv['secondary_type'],
      category: mv['category'],
      handler: (mv['handler'] || 'unique').underscore.camelize,
      pp: mv['pp'],
      power: mv['power'],
      priority: mv['priority'] || 0,
      accuracy: mv['accuracy'],
      meta: mv['meta'] || {},
      pokeapi_id: mv['pokeapi_id'],
      created_at: now,
      updated_at: now
    }
  end

  BattleEngine.logger.info("[Seeds] Inserting batch ##{batch_number} (#{db_batch.size} moves)...")
  Move.upsert_all(db_batch, unique_by: :name)
end

puts "¡Se han registrado #{Move.count} movimientos con éxito!"
