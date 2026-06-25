# frozen_string_literal: true

RSpec.shared_context 'single_battle_setup' do
  # Override these in your specs using `let(:player_1_pokemon) { [:snorlax, :scaledart] }` etc.
  let(:player_1_pokemon) { [] }
  let(:player_2_pokemon) { [] }

  # Override leads as symbols (e.g. `let(:player_1_lead) { :scaledart }`), defaults to player_1_pokemon.first
  let(:player_1_lead) { nil }
  let(:player_2_lead) { nil }

  let!(:battle) { create(:battle) }
  let!(:player_1) { create(:player) }
  let!(:player_2) { create(:player) }

  # Automatically registers players to the battle (sets up groups B and A respectively)
  let!(:battle_player_1) { create(:battle_player, battle: battle, player: player_1) }
  let!(:battle_player_2) { create(:battle_player, battle: battle, player: player_2) }

  let!(:team_1) { create(:team, player: player_1, name: 'Team 1') }
  let!(:team_2) { create(:team, player: player_2, name: 'Team 2') }

  let!(:player_1_pokemons) do
    player_1_pokemon.map { |sym| create(sym, team: team_1) }
  end

  let!(:player_2_pokemons) do
    player_2_pokemon.map { |sym| create(sym, team: team_2) }
  end

  let!(:player_1_snapshots) do
    player_1_pokemons.map do |pkmn|
      create(:pokemon_battle_snapshot, pokemon: pkmn, battle: battle, player: player_1)
    end
  end

  let!(:player_2_snapshots) do
    player_2_pokemons.map do |pkmn|
      create(:pokemon_battle_snapshot, pokemon: pkmn, battle: battle, player: player_2)
    end
  end

  # Resolve lead symbols
  let(:player_1_lead_symbol) { player_1_lead || player_1_pokemon.first }
  let(:player_2_lead_symbol) { player_2_lead || player_2_pokemon.first }

  let!(:player_1_lead_snapshot) do
    return nil if player_1_lead_symbol.nil?

    clean_lead_name = Spec::Support::LocalDataHelper.clean_factory_name(player_1_lead_symbol)
    player_1_snapshots.find do |snap|
      Spec::Support::LocalDataHelper.clean_factory_name(snap.pokemon.pokemon_template.name) == clean_lead_name
    end
  end

  let!(:player_2_lead_snapshot) do
    return nil if player_2_lead_symbol.nil?

    clean_lead_name = Spec::Support::LocalDataHelper.clean_factory_name(player_2_lead_symbol)
    player_2_snapshots.find do |snap|
      Spec::Support::LocalDataHelper.clean_factory_name(snap.pokemon.pokemon_template.name) == clean_lead_name
    end
  end

  # Position the leads on the field
  let!(:player_1_position) do
    return nil if player_1_lead_snapshot.nil?

    create(:position,
           field: battle.field,
           group: 1,
           side: battle_player_1.group,
           pokemon_snapshot: player_1_lead_snapshot)
  end

  let!(:player_2_position) do
    return nil if player_2_lead_snapshot.nil?

    create(:position,
           field: battle.field,
           group: 1,
           side: battle_player_2.group,
           pokemon_snapshot: player_2_lead_snapshot)
  end
end
