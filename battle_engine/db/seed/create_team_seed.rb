# frozen_string_literal: true

# rubocop:disable Style/GlobalVars
player_name = $seed_param
# rubocop:enable Style/GlobalVars

if player_name.nil? || player_name.strip.empty?
  BattleEngine.logger.error('[Seeds] Player name not specified. Usage: bundle exec rake "db:seed[create_team, PlayerName]"')
  exit 1
end

BattleEngine.logger.info("[Seeds] Finding or creating player '#{player_name}'...")
player = Player.find_or_create_by!(name: player_name)

# Count existing seeded teams for this player to generate the next name
seeded_teams_count = player.teams.where("name LIKE 'Team Seeded %'").count
team_name = "Team Seeded #{seeded_teams_count + 1}"

BattleEngine.logger.info("[Seeds] Creating team '#{team_name}' for player '#{player_name}'...")
team = player.teams.create!(name: team_name)

# Select 6 random templates
templates = PokemonTemplate.all.sample(6)
if templates.size < 6
  raise "Not enough PokemonTemplates in database (#{templates.size} found). Please run 'bundle exec rake \"db:seed[pokemon_template]\"' first."
end

BattleEngine.logger.info("[Seeds] Generating 6 random Pokémon for team '#{team_name}'...")

templates.each do |template|
  # Determine weight (fallback if template has no weight)
  weight = template.weight || rand(10.0..150.0).round(2)

  # Determine gender based on template's gender_rate
  gender = if template.gender_rate.nil? || template.gender_rate == -1
             nil
           elsif rand(8) < template.gender_rate
             Pokemon::FEMALE
           else
             Pokemon::MALE
           end

  # Determine nature
  nature = Nature::LIST.sample

  # Determine teratype
  teratype = Types::LIST.sample

  # Select 4 random moves that deal damage, fallback to any move if not enough damage moves
  damage_moves = template.moves.damage.to_a
  selected_moves = damage_moves.sample(4)

  if selected_moves.size < 4
    remaining = 4 - selected_moves.size
    other_moves = template.moves.where.not(id: selected_moves.map(&:id)).sample(remaining)
    selected_moves += other_moves
  end

  pokemon = Pokemon.create!(
    pokemon_template: template,
    team: team,
    nickname: template.name[0...10],
    gender: gender,
    nature: nature,
    weight: weight,
    ivs: { hp: 31, atk: 31, def: 31, sp_atk: 31, sp_def: 31, spd: 31 },
    evs: { hp: 0, atk: 0, def: 0, sp_atk: 0, sp_def: 0, spd: 0 },
    lvl: 50,
    teratype: teratype
  )

  selected_moves.each do |move|
    pokemon.attacks.create!(move: move)
  end

  BattleEngine.logger.info("[Seeds] Created Pokémon '#{pokemon.nickname}' (#{template.name}) with moves: #{selected_moves.map(&:name).join(', ')}")
end

BattleEngine.logger.info("[Seeds] Successfully created team '#{team_name}' with 6 Pokémon for #{player_name}!")
