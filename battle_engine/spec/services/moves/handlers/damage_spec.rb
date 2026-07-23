# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Services::Moves::Handlers::Damage, type: :service do
  include_context 'single_battle_setup'

  let(:player_1_pokemon) { [:milotic] }
  let(:player_2_pokemon) { [:metagross] }
  let(:player_1_pokemon_moves) do
    {
      milotic: %i[surf wrap]
    }
  end
  let(:player_2_pokemon_moves) do
    {
      metagross: %i[meteor_mash earthquake]
    }
  end

  subject do
    described_class.call(
      player_1_snapshots.first,
      player_2_snapshots.first,
      player_1_pokemons.first.moves.find { |move| move.name == 'Surf' }
    )
  end

  context 'with minimum random factor' do
    before do
      allow(Formulas).to receive(:random_factor).and_return(0.85)
    end

    it 'milotic does the correct damage to metagross using surf move' do
      expect { subject }.to change {
        player_2_snapshots.first.reload.hp
      }.by(57)
    end
  end

  context 'with maximun random factor' do
    before do
      allow(Formulas).to receive(:random_factor).and_return(1.0)
    end

    it 'milotic does the correct damage to metagross using surf move' do
      expect { subject }.to change {
        player_2_snapshots.first.reload.hp
      }.by(67)
    end
  end
end
