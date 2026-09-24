# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'BattleSetup' do
  describe 'shared context battle_setup with simple pokemon config (default lead)', :aggregate_failures do
    include_context 'single_battle_setup'

    let(:player_1_pokemon_config) { %i[snorlax scaledart] }
    let(:player_2_pokemon_config) { [:dracocoon, { pokemon: :dracanfly }] }

    it 'correctly initializes the battle with players, teams, and snapshots' do
      aggregate_failures do
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

    it 'positions the default leads (first in the list) on the field' do
      aggregate_failures do
        expect(player_1_position).to be_persisted
        expect(player_1_position.field).to eq(battle.field)
        expect(player_1_position.pokemon_snapshot).to eq(player_1_snapshots.first)
        expect(player_1_position.side).to eq('B')
        expect(player_1_position.group).to eq(1)

        expect(player_2_position).to be_persisted
        expect(player_2_position.field).to eq(battle.field)
        expect(player_2_position.pokemon_snapshot).to eq(player_2_snapshots.first)
        expect(player_2_position.side).to eq('A')
        expect(player_2_position.group).to eq(1)
      end
    end
  end

  describe 'shared context battle_setup with explicit lead: true flag', :aggregate_failures do
    include_context 'single_battle_setup'

    let(:player_1_pokemon_config) do
      [
        { pokemon: :snorlax },
        { pokemon: :scaledart, lead: true }
      ]
    end

    let(:player_2_pokemon_config) do
      [
        { pokemon: :dracocoon },
        { pokemon: :dracanfly, lead: true }
      ]
    end

    it 'positions the pokemon with lead: true on the field' do
      aggregate_failures do
        expect(player_1_position.pokemon_snapshot.pokemon.pokemon_template.name).to eq('Scaledart')
        expect(player_2_position.pokemon_snapshot.pokemon.pokemon_template.name).to eq('Dracanfly')
      end
    end
  end

  describe 'shared context battle_setup with multiple lead: true flags', :aggregate_failures do
    include_context 'single_battle_setup'

    let(:player_1_pokemon_config) do
      [
        { pokemon: :snorlax, lead: true },
        { pokemon: :scaledart, lead: true }
      ]
    end

    it 'picks the first lead: true pokemon in the list' do
      expect(player_1_position.pokemon_snapshot.pokemon.pokemon_template.name).to eq('Snorlax')
    end
  end

  describe 'shared context battle_setup with custom object configuration', :aggregate_failures do
    include_context 'single_battle_setup'

    let(:player_1_pokemon_config) do
      [
        {
          pokemon: :milotic,
          moves: %i[surf tackle],
          nature: Nature::MODEST,
          lvl: 70,
          ivs: { hp: 31, sp_atk: 31 },
          evs: { hp: 252, sp_atk: 252 }
        }
      ]
    end

    let(:player_2_pokemon_config) do
      [
        {
          pokemon: :metagross,
          moves: %i[meteor_mash earthquake]
        }
      ]
    end

    it 'assigns specified moves, nature, level, IVs, and EVs correctly' do
      aggregate_failures do
        milotic = player_1_pokemons.first
        expect(milotic.pokemon_template.name).to eq('Milotic')
        expect(milotic.moves.map(&:name)).to contain_exactly('Surf', 'Tackle')
        expect(milotic.nature).to eq('Modest')
        expect(milotic.lvl).to eq(70)
        expect(milotic.ivs['hp']).to eq(31)
        expect(milotic.evs['sp_atk']).to eq(252)

        metagross = player_2_pokemons.first
        expect(metagross.pokemon_template.name).to eq('Metagross')
        expect(metagross.moves.map(&:name)).to contain_exactly('Meteor Mash', 'Earthquake')
      end
    end
  end
end
