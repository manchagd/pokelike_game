# frozen_string_literal: true

RSpec.shared_context 'battle_setup' do
  # Override these in your specs using `let(:player_1_pokemon) { [:snorlax, :scaledart] }` etc.
  let(:player_1_pokemon) { [] }
  let(:player_2_pokemon) { [] }

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
end
