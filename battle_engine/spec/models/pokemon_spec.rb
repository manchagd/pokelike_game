# frozen_string_literal: true

require 'pry'
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
    context 'when Snorlax is at lvl 50 with Adamant nature, perfect IVs and 252 EV in HP and 252 EV in Attack' do
      subject do
        create(
          :snorlax,
          lvl: 50,
          nature: Nature::ADAMANT,
          evs: { 'hp' => 252, 'atk' => 252, 'def' => 6 },
          ivs: { 'hp' => 31, 'atk' => 31, 'def' => 31, 'sp_atk' => 31, 'sp_def' => 31, 'spd' => 31 }
        )
      end

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

    context 'when Snorlax is at lvl 100 with Brave nature, perfect IVs and 252 EV in HP and 252 EV in Attack' do
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

    context 'when Snorlax is at lvl 25 with neutral nature, mixed IVs and 252 EV in Def and 252 EV in SpDef' do
      subject do
        create(
          :snorlax,
          lvl: 25,
          nature: Nature::HARDY,
          evs: { 'hp' => 6, 'def' => 252, 'sp_def' => 252 },
          ivs: { 'hp' => 10, 'atk' => 15, 'def' => 20, 'sp_atk' => 25, 'sp_def' => 31, 'spd' => 0 }
        )
      end

      it_behaves_like(
        'pokemon_with_stats',
        hp: 117,
        atk: 63,
        def: 58,
        sp_atk: 43,
        sp_def: 83,
        spd: 20
      )
    end

    context 'when Florges is at lvl 75 with Calm nature, perfect IVs and mixed EVs distribution' do
      subject do
        create(
          :florges,
          lvl: 75,
          nature: Nature::CALM,
          evs: { 'hp' => 25, 'sp_atk' => 60, 'sp_def' => 204, 'spd' => 102 },
          ivs: { 'hp' => 31, 'atk' => 31, 'def' => 31, 'sp_atk' => 31, 'sp_def' => 31, 'spd' => 31 }
        )
      end

      it_behaves_like(
        'pokemon_with_stats',
        hp: 229,
        atk: 112,
        def: 130,
        sp_atk: 207,
        sp_def: 326,
        spd: 159
      )
    end

    context 'when Metagross is at lvl 73 with Adamant nature, mixed IVs and mixed EVs distribution' do
      subject do
        create(
          :metagross,
          lvl: 73,
          nature: Nature::ADAMANT,
          evs: { 'hp' => 50, 'atk' => 115, 'def' => 16, 'sp_def' => 48, 'spd' => 189 },
          ivs: { 'hp' => 31, 'atk' => 31, 'def' => 31, 'sp_atk' => 17, 'sp_def' => 28, 'spd' => 1 }
        )
      end

      it_behaves_like(
        'pokemon_with_stats',
        hp: 231,
        atk: 269,
        def: 220,
        sp_atk: 140,
        sp_def: 165,
        spd: 142
      )
    end

    context 'when Empoleon is at lvl 88 with Modest nature, 0 IVs and 252 EV in Hp and 252 EV in SpAtk' do
      subject do
        create(
          :empoleon,
          lvl: 88,
          nature: Nature::MODEST,
          evs: { 'hp' => 252, 'sp_atk' => 252, 'sp_def' => 6 },
          ivs: { 'hp' => 0, 'atk' => 0, 'def' => 0, 'sp_atk' => 0, 'sp_def' => 0, 'spd' => 0 }
        )
      end

      it_behaves_like(
        'pokemon_with_stats',
        hp: 301,
        atk: 140,
        def: 159,
        sp_atk: 280,
        sp_def: 183,
        spd: 110
      )
    end

    context 'when Zubat is at lvl 1 with neutral nature, mixed IVs and mixed EV distrinution' do
      subject do
        create(
          :zubat,
          lvl: 1,
          nature: Nature::BASHFUL,
          evs: { 'hp' => 15, 'atk' => 25, 'def' => 20, 'sp_atk' => 30, 'sp_def' => 25, 'spd' => 35 },
          ivs: { 'hp' => 0, 'atk' => 10, 'def' => 5, 'sp_atk' => 15, 'sp_def' => 10, 'spd' => 20 }
        )
      end

      it_behaves_like(
        'pokemon_with_stats',
        hp: 11,
        atk: 6,
        def: 5,
        sp_atk: 5,
        sp_def: 5,
        spd: 6
      )
    end

    context 'when Metapod is at lvl 7 with Bold nature, perfect IVs and 0 EVs' do
      subject do
        create(
          :metapod,
          lvl: 7,
          nature: Nature::BOLD,
          evs: {},
          ivs: { 'hp' => 31, 'atk' => 31, 'def' => 31, 'sp_atk' => 31, 'sp_def' => 31, 'spd' => 31 }
        )
      end

      it_behaves_like(
        'pokemon_with_stats',
        hp: 26,
        atk: 8,
        def: 15,
        sp_atk: 10,
        sp_def: 10,
        spd: 11
      )
    end

    context 'when Metagross is at lvl 73, but IVs and EVs are empty it sets them to 0' do
      subject do
        create(
          :metagross,
          lvl: 73,
          nature: Nature::ADAMANT,
          evs: {},
          ivs: {}
        )
      end

      it_behaves_like(
        'pokemon_with_stats',
        hp: 199,
        atk: 222,
        def: 194,
        sp_atk: 128,
        sp_def: 136,
        spd: 107
      )
    end
  end
end
