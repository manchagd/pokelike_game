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
end
