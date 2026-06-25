# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pokemon, type: :model do
  describe 'factories', :aggregate_failures do
    let(:battle) { create(:battle) }
    let(:player) { create(:player) }

    context 'using pokeapi.co pokemon_templates' do
      let(:move) { create(:tackle) }
      let(:template) { create(:snorlax_template) }
      let(:pokemon) { create(:snorlax) }
      let(:snapshot) { create(:snorlax_snapshot, battle: battle, player: player) }

      it 'creates a valid Snorlax template from local data' do
        expect(template).to be_persisted
        expect(template.name).to eq('Snorlax')
        expect(template.types).to eq(['Normal'])
        expect(template.stats['hp']).to eq(160)
      end

      it 'creates a valid Snorlax Pokemon instance with calculated stats' do
        expect(pokemon).to be_persisted
        expect(pokemon.pokemon_template.name).to eq('Snorlax')
        expect(pokemon.lvl).to eq(50)
        expect(pokemon.hp_stat).to eq(235)
      end

      it 'creates a valid Snorlax snapshot for a battle' do
        expect(snapshot).to be_persisted
        expect(snapshot.battle).to eq(battle)
        expect(snapshot.player).to eq(player)
        expect(snapshot.pokemon.pokemon_template.name).to eq('Snorlax')
        expect(snapshot.hp).to eq(snapshot.pokemon.hp_stat)
      end

      it 'creates a valid Tackle move from local data' do
        expect(move).to be_persisted
        expect(move.name).to eq('Tackle')
        expect(move.type).to eq('Normal')
        expect(move.power).to eq(40)
        expect(move.handler).to eq('Damage')
      end
    end

    context 'using custom pokémon templates' do
      let(:move) { create(:scale_pulse) }
      let(:template) { create(:scaledart_template) }
      let(:pokemon) { create(:scaledart) }
      let(:snapshot) { create(:scaledart_snapshot) }

      it 'creates a valid custom Scaledart template, instance, and snapshot dynamically' do
        expect(template).to be_persisted
        expect(template.name).to eq('Scaledart')
        expect(template.types).to eq(['Bug'])

        expect(pokemon).to be_persisted
        expect(pokemon.pokemon_template).to eq(template)

        expect(snapshot).to be_persisted
        expect(snapshot.pokemon.pokemon_template.name).to eq('Scaledart')
      end

      it 'creates a valid custom Scale Pulse move dynamically' do
        expect(move).to be_persisted
        expect(move.name).to eq('Scale Pulse')
        expect(move.type).to eq('Bug')
        expect(move.secondary_type).to eq('Dragon')
        expect(move.power).to eq(95)
        expect(move.handler).to eq('Damage')
      end
    end
  end

  describe 'calculated stats' do
    context 'when Snorlax is at lvl 50 with Adamant nature, and 252 EV in HP and 252 EV in Attack' do
      subject { create(:snorlax, lvl: 50, nature: Nature::ADAMANT, evs: { 'hp' => 252, 'atk' => 252, 'def' => 6 }, ivs: { 'hp' => 31, 'atk' => 31, 'def' => 31, 'sp_atk' => 31, 'sp_def' => 31, 'spd' => 31 }) }

      it_behaves_like(
        'pokemon_with_stats',
        hp: 267,
        atk: 178,
        def: 86,
        sp_atk: 76,
        sp_def: 130,
        spd: 50
      )
    end

    context 'when Snorlax is at lvl 50 with Adamant nature, and 252 EV in HP and 252 EV in Attack' do
      subject do
        create(
          :snorlax,
          lvl: 100,
          nature: Nature::BRAVE,
          evs: { 'hp' => 252, 'atk' => 252, 'def' => 6 },
          ivs: { 'hp' => 31, 'atk' => 31, 'def' => 31, 'sp_atk' => 31, 'sp_def' => 31, 'spd' => 0 }
        )
      end

      it_behaves_like(
        'pokemon_with_stats',
        hp: 524,
        atk: 350,
        def: 167,
        sp_atk: 166,
        sp_def: 256,
        spd: 58
      )
    end
  end
end
