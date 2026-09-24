# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Teams Services', type: :service do
  let(:player) { create(:player) }
  let(:snorlax_template) { create(:snorlax_template) }
  let(:pikachu_template) { create(:pokemon_template, name: 'Pikachu', gender_rate: 4) } # 50% Male / 50% Female
  let(:genderless_template) { create(:pokemon_template, name: 'Mew', gender_rate: -1) } # Genderless

  let(:tackle) { create(:tackle) }

  describe Services::Teams::CreateTeamService do
    subject(:service) { described_class.new }

    it 'creates a new team with pokemons and attacks' do
      pokemons_data = [
        {
          pokemon_template_id: snorlax_template.id,
          nickname: 'Chubby',
          gender: 'Male',
          nature: 'Adamant',
          ivs: { hp: 31, atk: 31 },
          evs: { hp: 252, atk: 252 },
          moves: [tackle.id]
        }
      ]

      expect do
        service.call(player: player, name: 'My Great Team', pokemons: pokemons_data)
      end.to change(Team, :count).by(1).and change(Pokemon, :count).by(1)

      team = player.teams.last
      expect(team.name).to eq('My Great Team')

      pokemon = team.pokemons.first
      expect(pokemon.pokemon_template).to eq(snorlax_template)
      expect(pokemon.nickname).to eq('Chubby')
      expect(pokemon.gender).to eq('Male')
      expect(pokemon.nature).to eq('Adamant')
      expect(pokemon.ivs['hp']).to eq(31)
      expect(pokemon.evs['hp']).to eq(252)
      if snorlax_template.weight
        expect(pokemon.weight).to eq(snorlax_template.weight)
      else
        expect(pokemon.weight).to be_between(10.0, 150.0)
      end
      expect(pokemon.attacks.count).to eq(1)
    end

    it 'resolves duplicate name by appending timestamp' do
      create(:team, player: player, name: 'Unique Name')

      service.call(player: player, name: 'Unique Name', pokemons: [])
      team = player.teams.last
      expect(team.name).to start_with('Unique Name (')
    end

    it 'applies defaults and fallbacks for gender, nature, weight, and teratype' do
      pokemons_data = [
        {
          pokemon_template_id: pikachu_template.id
          # no nickname, gender, nature, ivs, evs
        },
        {
          pokemon_template_id: genderless_template.id
        }
      ]

      expect do
        service.call(player: player, name: 'Defaults Team', pokemons: pokemons_data)
      end.to change(Pokemon, :count).by(2)

      team = player.teams.last
      first_pokemon = team.pokemons.first
      second_pokemon = team.pokemons.last

      # Pikachu has gender_rate 4, so it should be either Male or Female (never nil/genderless)
      expect(%w[Male Female]).to include(first_pokemon.gender)
      # Mew has gender_rate -1, so it should be genderless (nil)
      expect(second_pokemon.gender).to be_nil

      # Nicknames should default to template name (truncated to 10 chars)
      expect(first_pokemon.nickname).to eq('Pikachu')
      expect(second_pokemon.nickname).to eq('Mew')

      # Nature should be filled randomly from list
      expect(Nature::LIST).to include(first_pokemon.nature)

      # Teratype should default to template type
      expect(first_pokemon.teratype).to eq('Electric')
    end
  end

  describe Services::Teams::UpdateTeamService do
    subject(:service) { described_class.new }
    let!(:team) { create(:team, player: player, name: 'Old Name') }
    let!(:existing_pokemon) { create(:pokemon, team: team, pokemon_template: snorlax_template, nickname: 'Snorlax', nature: 'Hardy') }

    it 'updates team name and existing pokemon details' do
      pokemons_data = [
        {
          pokemon_template_id: snorlax_template.id,
          nickname: 'Fatty',
          nature: 'Relaxed',
          gender: 'Female',
          ivs: { hp: 30 },
          evs: { hp: 100 },
          moves: []
        }
      ]

      expect do
        service.call(player: player, team_id: team.id, name: 'New Name', pokemons: pokemons_data)
      end.not_to change(Pokemon, :count)

      expect(team.reload.name).to eq('New Name')
      expect(existing_pokemon.reload.nickname).to eq('Fatty')
      expect(existing_pokemon.nature).to eq('Relaxed')
      expect(existing_pokemon.gender).to eq('Female')
      expect(existing_pokemon.ivs['hp']).to eq(30)
      expect(existing_pokemon.evs['hp']).to eq(100)
    end

    it 'adds new pokemons when count increases, and deletes extra when count decreases' do
      # 1. Increase count to 2
      pokemons_data = [
        { pokemon_template_id: snorlax_template.id },
        { pokemon_template_id: pikachu_template.id }
      ]

      expect do
        service.call(player: player, team_id: team.id, name: 'Updated Team', pokemons: pokemons_data)
      end.to change(Pokemon, :count).by(1)

      expect(team.pokemons.count).to eq(2)
      second_pokemon = team.pokemons.last
      expect(second_pokemon.pokemon_template).to eq(pikachu_template)

      # 2. Decrease count to 1
      pokemons_data = [
        { pokemon_template_id: pikachu_template.id } # Replacing the first one with Pikachu template, deleting second
      ]

      expect do
        service.call(player: player, team_id: team.id, name: 'Updated Team', pokemons: pokemons_data)
      end.to change(Pokemon, :count).by(-1)

      expect(team.pokemons.count).to eq(1)
      expect(team.pokemons.first.pokemon_template).to eq(pikachu_template)
    end
  end

  describe Services::Teams::DeleteTeamService do
    subject(:service) { described_class.new }
    let!(:team) { create(:team, player: player) }
    let!(:pokemon_without_snapshots) { create(:pokemon, team: team, pokemon_template: snorlax_template) }
    let!(:pokemon_with_snapshots) { create(:pokemon, team: team, pokemon_template: pikachu_template) }
    let!(:snapshot) { create(:pokemon_battle_snapshot, pokemon: pokemon_with_snapshots, player: player) }
    let!(:position) { create(:position, pokemon_snapshot: snapshot) }

    before do
      allow(Publishers::PlayerEventsPublisher).to receive(:publish)
    end

    it 'deletes the team and destroys pokemons without snapshots, but keeps pokemons with snapshots as teamless' do
      expect do
        service.call(player_id: player.id, team_id: team.id)
      end.to change(Team, :count).by(-1)
                                 .and change(Pokemon, :count).by(-1)

      expect(Pokemon.exists?(pokemon_without_snapshots.id)).to be_falsey
      expect(Pokemon.exists?(pokemon_with_snapshots.id)).to be_truthy
      expect(pokemon_with_snapshots.reload.team_id).to be_nil
    end
  end
end
