# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pokemon, type: :model do
  describe 'factories' do
    it 'creates a valid Snorlax template from local data' do
      template = create(:snorlax_template)
      expect(template).to be_persisted
      expect(template.name).to eq('Snorlax')
      expect(template.types).to eq(['Normal'])
      expect(template.stats['hp']).to eq(160)
    end

    it 'creates a valid Snorlax Pokemon instance with calculated stats' do
      pokemon = create(:snorlax)
      expect(pokemon).to be_persisted
      expect(pokemon.pokemon_template.name).to eq('Snorlax')
      expect(pokemon.lvl).to eq(50)
      expect(pokemon.hp_stat).to be > 0
    end

    it 'creates a valid Snorlax snapshot for a battle' do
      battle = create(:battle)
      player = create(:player)
      snapshot = create(:snorlax_snapshot, battle: battle, player: player)

      expect(snapshot).to be_persisted
      expect(snapshot.battle).to eq(battle)
      expect(snapshot.player).to eq(player)
      expect(snapshot.pokemon.pokemon_template.name).to eq('Snorlax')
      expect(snapshot.hp).to eq(snapshot.pokemon.hp_stat)
    end

    it 'creates a valid Tackle move from local data' do
      move = create(:tackle)
      expect(move).to be_persisted
      expect(move.name).to eq('Tackle')
      expect(move.type).to eq('Normal')
      expect(move.power).to eq(40)
      expect(move.handler).to eq('Damage')
    end

    it 'creates a valid custom Scaledart template, instance, and snapshot dynamically' do
      template = create(:scaledart_template)
      expect(template).to be_persisted
      expect(template.name).to eq('Scaledart')
      expect(template.types).to eq(['Bug'])

      pokemon = create(:scaledart)
      expect(pokemon.pokemon_template).to eq(template)

      snapshot = create(:scaledart_snapshot)
      expect(snapshot.pokemon.pokemon_template.name).to eq('Scaledart')
    end

    it 'creates a valid custom Scale Pulse move dynamically' do
      move = create(:scale_pulse)
      expect(move).to be_persisted
      expect(move.name).to eq('Scale Pulse')
      expect(move.type).to eq('Bug')
      expect(move.secondary_type).to eq('Dragon')
      expect(move.power).to eq(95)
      expect(move.handler).to eq('Damage')
    end
  end

  describe 'shared context battle_setup' do
    include_context 'battle_setup'
    let(:player_1_pokemon) { [:snorlax, :scaledart] }
    let(:player_2_pokemon) { [:dracocoon, :dracanfly] }

    it 'correctly initializes the battle with players, teams, and snapshots' do
      expect(battle).to be_persisted
      expect(player_1).to be_persisted
      expect(player_2).to be_persisted

      # Check automatic group assignment (first gets B, second gets A)
      expect(battle_player_1.group).to eq('B')
      expect(battle_player_2.group).to eq('A')

      # Check teams association
      expect(team_1.player).to eq(player_1)
      expect(team_2.player).to eq(player_2)

      # Check player 1 pokemons
      expect(player_1_pokemons.size).to eq(2)
      expect(player_1_pokemons.first.pokemon_template.name).to eq('Snorlax')
      expect(player_1_pokemons.second.pokemon_template.name).to eq('Scaledart')

      # Check player 2 pokemons
      expect(player_2_pokemons.size).to eq(2)
      expect(player_2_pokemons.first.pokemon_template.name).to eq('Dracocoon')
      expect(player_2_pokemons.second.pokemon_template.name).to eq('Dracanfly')

      # Check snapshots and hp matching calculated stats
      expect(player_1_snapshots.size).to eq(2)
      expect(player_1_snapshots.first.pokemon.pokemon_template.name).to eq('Snorlax')
      expect(player_1_snapshots.first.hp).to eq(player_1_pokemons.first.hp_stat)

      expect(player_2_snapshots.size).to eq(2)
      expect(player_2_snapshots.first.pokemon.pokemon_template.name).to eq('Dracocoon')
      expect(player_2_snapshots.first.hp).to eq(player_2_pokemons.first.hp_stat)
    end
  end
end
