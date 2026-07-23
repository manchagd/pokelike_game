# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'BattleSetup' do
  describe 'shared context battle_setup with default leads', :aggregate_failures do
    include_context 'single_battle_setup'

    let(:player_1_pokemon) { %i[snorlax scaledart] }
    let(:player_2_pokemon) { %i[dracocoon dracanfly] }

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

  describe 'shared context battle_setup with overridden leads', :aggregate_failures do
    include_context 'single_battle_setup'
    let(:player_1_pokemon) { %i[snorlax scaledart] }
    let(:player_2_pokemon) { %i[dracocoon dracanfly] }
    let(:player_1_lead) { :scaledart }
    let(:player_2_lead) { :dracanfly }

    it 'positions the custom specified lead pokemons on the field' do
      aggregate_failures do
        expect(player_1_position.pokemon_snapshot.pokemon.pokemon_template.name).to eq('Scaledart')
        expect(player_2_position.pokemon_snapshot.pokemon.pokemon_template.name).to eq('Dracanfly')
      end
    end
  end

  describe 'shared context battle_setup with explicit pokemon moves', :aggregate_failures do
    include_context 'single_battle_setup'

    let(:player_1_pokemon) { %i[snorlax scaledart] }
    let(:player_2_pokemon) { %i[dracocoon dracanfly] }

    let(:player_1_pokemon_moves) do
      {
        snorlax: %i[tackle surf],
        scaledart: %i[surf tackle]
      }
    end

    let(:player_2_pokemon_moves) do
      {
        dracocoon: %i[tackle surf],
        dracanfly: %i[surf tackle]
      }
    end

    it 'assigns the multiple specified moves to the respective pokemons' do
      aggregate_failures do
        # Verificar movimientos de Player 1
        snorlax = player_1_pokemons.find { |p| p.pokemon_template.name == 'Snorlax' }
        expect(snorlax.moves.map(&:name)).to contain_exactly('Tackle', 'Surf')

        scaledart = player_1_pokemons.find { |p| p.pokemon_template.name == 'Scaledart' }
        expect(scaledart.moves.map(&:name)).to contain_exactly('Surf', 'Tackle')

        # Verificar movimientos de Player 2
        dracocoon = player_2_pokemons.find { |p| p.pokemon_template.name == 'Dracocoon' }
        expect(dracocoon.moves.map(&:name)).to contain_exactly('Tackle', 'Surf')

        dracanfly = player_2_pokemons.find { |p| p.pokemon_template.name == 'Dracanfly' }
        expect(dracanfly.moves.map(&:name)).to contain_exactly('Surf', 'Tackle')
      end
    end
  end
end
