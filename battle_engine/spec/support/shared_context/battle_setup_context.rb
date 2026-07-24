# frozen_string_literal: true

RSpec.shared_context 'single_battle_setup' do
  # Override player_1_pokemon_config and player_2_pokemon_config in your specs.
  # Elements can be symbols (e.g. `:snorlax`) or hashes with full configuration options:
  #
  # Example:
  # let(:player_1_pokemon_config) do
  #   [
  #     {
  #       pokemon: :milotic,                              # (Symbol/String, Required) Factory symbol or template name (aliases: :template, :name)
  #       moves: %i[surf scald flamethrower tackle],     # (Array of Symbols/Strings, Optional) Move factory names or instances
  #       nature: Nature::MODEST,                         # (String, Optional) Nature name (e.g. 'Modest', Nature::ADAMANT)
  #       lvl: 50,                                        # (Integer, Optional) Level (alias: :level, default: 50)
  #       ivs: { hp: 31, atk: 31, def: 31, sp_atk: 31 },  # (Hash, Optional) IVs map (default: all 31)
  #       evs: { hp: 252, sp_atk: 252 },                  # (Hash, Optional) EVs map (default: all 0)
  #       nickname: 'Milo',                               # (String, Optional) Custom nickname (max 10 chars)
  #       gender: Pokemon::FEMALE,                        # (String, Optional) Pokemon::FEMALE or Pokemon::MALE
  #       teratype: Types::WATER,                         # (String, Optional) Types::WATER, Types::FIRE, etc.
  #       weight: 162.0,                                  # (Float, Optional) Pokemon weight
  #       lead: true                                      # (Boolean, Optional) Lead marker on field (alias: :is_lead)
  #     },
  #     :dracanfly                                        # Simple shorthand syntax
  #   ]
  # end
  let(:player_1_pokemon_config) { [] }
  let(:player_2_pokemon_config) { [] }

  let!(:battle) { create(:battle) }
  let!(:player_1) { create(:player) }
  let!(:player_2) { create(:player) }

  # Automatically registers players to the battle (sets up groups B and A respectively)
  let!(:battle_player_1) { create(:battle_player, battle: battle, player: player_1) }
  let!(:battle_player_2) { create(:battle_player, battle: battle, player: player_2) }

  let!(:team_1) { create(:team, player: player_1, name: 'Team 1') }
  let!(:team_2) { create(:team, player: player_2, name: 'Team 2') }

  def build_pokemons_from_config(config, team)
    default_ivs = { 'hp' => 31, 'atk' => 31, 'def' => 31, 'sp_atk' => 31, 'sp_def' => 31, 'spd' => 31 }.freeze
    default_evs = { 'hp' => 0, 'atk' => 0, 'def' => 0, 'sp_atk' => 0, 'sp_def' => 0, 'spd' => 0 }.freeze

    config.map do |cfg|
      raw_cfg = cfg.is_a?(Hash) ? cfg : { pokemon: cfg }
      factory_name = (raw_cfg[:pokemon] || raw_cfg[:template] || raw_cfg[:name]).to_sym

      attrs = { team: team }
      attrs[:nickname] = raw_cfg[:nickname] if raw_cfg.key?(:nickname)
      attrs[:gender]   = raw_cfg[:gender]   if raw_cfg.key?(:gender)
      attrs[:nature]   = raw_cfg[:nature]   if raw_cfg.key?(:nature)
      attrs[:weight]   = raw_cfg[:weight]   if raw_cfg.key?(:weight)
      attrs[:teratype] = raw_cfg[:teratype] if raw_cfg.key?(:teratype)

      lvl = raw_cfg[:lvl] || raw_cfg[:level]
      attrs[:lvl] = lvl if lvl.present?

      attrs[:ivs] = default_ivs.merge(raw_cfg[:ivs].transform_keys(&:to_s)) if raw_cfg.key?(:ivs)

      attrs[:evs] = default_evs.merge(raw_cfg[:evs].transform_keys(&:to_s)) if raw_cfg.key?(:evs)

      move_inputs = Array(raw_cfg[:moves])
      moves_to_assign = move_inputs.map do |m|
        m.is_a?(Symbol) || m.is_a?(String) ? create(m.to_sym) : m
      end
      attrs[:moves] = moves_to_assign

      create(factory_name, **attrs)
    end
  end

  def find_lead_index_from_config(config)
    lead_idx = config.find_index do |cfg|
      cfg.is_a?(Hash) && (cfg[:lead] == true || cfg[:is_lead] == true)
    end
    lead_idx || 0
  end

  let!(:player_1_pokemons) do
    build_pokemons_from_config(player_1_pokemon_config, team_1)
  end

  let!(:player_2_pokemons) do
    build_pokemons_from_config(player_2_pokemon_config, team_2)
  end

  let!(:player_1_snapshots) do
    player_1_pokemons.map do |pkmn|
      FactoryBot.create(:pokemon_battle_snapshot, pokemon: pkmn, battle: battle, player: player_1)
    end
  end

  let!(:player_2_snapshots) do
    player_2_pokemons.map do |pkmn|
      FactoryBot.create(:pokemon_battle_snapshot, pokemon: pkmn, battle: battle, player: player_2)
    end
  end

  let!(:player_1_lead_snapshot) do
    return if player_1_snapshots.empty?

    idx = find_lead_index_from_config(player_1_pokemon_config)
    player_1_snapshots[idx]
  end

  let!(:player_2_lead_snapshot) do
    return if player_2_snapshots.empty?

    idx = find_lead_index_from_config(player_2_pokemon_config)
    player_2_snapshots[idx]
  end

  let!(:player_1_position) do
    if player_1_lead_snapshot.present?
      FactoryBot.create(:position,
                        field: battle.field,
                        group: 1,
                        side: battle_player_1.group,
                        pokemon_snapshot: player_1_lead_snapshot)
    end
  end

  let!(:player_2_position) do
    if player_2_lead_snapshot.present?
      FactoryBot.create(:position,
                        field: battle.field,
                        group: 1,
                        side: battle_player_2.group,
                        pokemon_snapshot: player_2_lead_snapshot)
    end
  end
end
