# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Services::Moves::Handlers::Damage, type: :service do
  include_context 'single_battle_setup'
  describe 'Milotic VS Metagross' do
    let(:player_1_pokemon) { [:milotic] }
    let(:player_2_pokemon) { [:metagross] }
    let(:player_1_pokemon_moves) do
      {
        milotic: %i[surf tackle flamethrower]
      }
    end
    let(:player_2_pokemon_moves) do
      {
        metagross: %i[meteor_mash earthquake]
      }
    end

    # Pensar en refactorizar el shared context para recibir la lista de los pokemon y sus posibles variaciones
    # no solamente la lista de ataque sino sus naturalezas, EVs e Ivs, en un json
    # y construir los pokemons con base en estos parametros
    let(:move_name) { '' }
    let(:milotic) { player_1_snapshots.first }
    let(:metagross) { player_2_snapshots.first }
    let(:move) { player_1_pokemons.first.moves.find { |move| move.name == move_name } }

    subject do
      described_class.call(milotic, metagross, move)
    end

    context 'when attack is Surf (neutral damage)' do
      let(:move_name) { 'Surf' }

      context 'with minimum random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(0.85)
        end

        it 'milotic does the correct damage to metagross' do
          expect { subject }.to change {
            player_2_snapshots.first.reload.hp
          }.by(-57)
        end
      end

      context 'with maximun random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(1.0)
        end

        it 'milotic does the correct damage to metagross' do
          expect { subject }.to change {
            player_2_snapshots.first.reload.hp
          }.by(-67)
        end
      end
    end

    context 'when attack is Flamethrower (2x damage)' do
      let(:move_name) { 'Flamethrower' }

      context 'with minimum random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(0.85)
        end

        it 'milotic does the correct damage to metagross' do
          expect { subject }.to change {
            player_2_snapshots.first.reload.hp
          }.by(-76)
        end
      end

      context 'with maximun random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(1.0)
        end

        it 'milotic does the correct damage to metagross' do
          expect { subject }.to change {
            player_2_snapshots.first.reload.hp
          }.by(-90)
        end
      end
    end

    context 'when attack is Tackle (0.5x damage)' do
      let(:move_name) { 'Tackle' }

      context 'with minimum random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(0.85)
        end

        it 'milotic does the correct damage to metagross' do
          expect { subject }.to change {
            player_2_snapshots.first.reload.hp
          }.by(-4)
        end
      end

      context 'with maximun random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(1.0)
        end

        it 'milotic does the correct damage to metagross' do
          expect { subject }.to change {
            player_2_snapshots.first.reload.hp
          }.by(-5)
        end
      end
    end
  end

  describe 'Togekiss VS Tyranitar' do
    let(:player_1_pokemon) { [:togekiss] }
    let(:player_2_pokemon) { [:tyranitar] }
    let(:player_1_pokemon_moves) do
      {
        togekiss: %i[air_slash aura_sphere liquidation ice_beam]
      }
    end
    let(:player_2_pokemon_moves) do
      {
        tyranitar: %i[stone_edge earthquake]
      }
    end

    let(:move_name) { '' }
    let(:togekiss) { player_1_snapshots.first }
    let(:tyranitar) { player_2_snapshots.first }
    let(:move) { player_1_pokemons.first.moves.find { |move| move.name == move_name } }

    subject do
      described_class.call(togekiss, tyranitar, move)
    end

    context 'when attack is Aura Sphere (4x damage)' do
      let(:move_name) { 'Aura Sphere' }

      context 'with minimum random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(0.85)
        end

        it 'togekiss does the correct damage to tyranitar' do
          expect { subject }.to change {
            player_2_snapshots.first.reload.hp
          }.by(-146)
        end
      end

      context 'with maximun random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(1.0)
        end

        it 'togekiss does the correct damage to tyranitar' do
          expect { subject }.to change {
            player_2_snapshots.first.reload.hp
          }.by(-172)
        end
      end
    end

    context 'when attack is Liquidation (2x damage)' do
      let(:move_name) { 'Liquidation' }

      context 'with minimum random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(0.85)
        end

        it 'togekiss does the correct damage to tyranitar' do
          expect { subject }.to change {
            tyranitar.reload.hp
          }.by(-37)
        end
      end

      context 'with maximun random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(1.0)
        end

        it 'togekiss does the correct damage to tyranitar' do
          expect { subject }.to change {
            tyranitar.reload.hp
          }.by(-44)
        end
      end
    end

    context 'when attack is Ice Beam (neutral damage)' do
      let(:move_name) { 'Ice Beam' }

      context 'with minimum random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(0.85)
        end

        it 'togekiss does the correct damage to tyranitar' do
          expect { subject }.to change {
            tyranitar.reload.hp
          }.by(-41)
        end
      end

      context 'with maximun random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(1.0)
        end

        it 'togekiss does the correct damage to tyranitar' do
          expect { subject }.to change {
            tyranitar.reload.hp
          }.by(-48)
        end
      end
    end

    context 'when attack is Air Slash (0.5x damage)' do
      let(:move_name) { 'Air Slash' }

      context 'with minimum random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(0.85)
        end

        it 'togekiss does the correct damage to tyranitar' do
          expect { subject }.to change {
            player_2_snapshots.first.reload.hp
          }.by(-25)
        end
      end

      context 'with maximun random factor' do
        before do
          allow(Formulas).to receive(:random_factor).and_return(1.0)
        end

        it 'togekiss does the correct damage to tyranitar' do
          expect { subject }.to change {
            player_2_snapshots.first.reload.hp
          }.by(-30)
        end
      end
    end
  end
end
