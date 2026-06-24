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
end
