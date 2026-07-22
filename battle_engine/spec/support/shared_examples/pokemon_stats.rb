# frozen_string_literal: true

RSpec.shared_examples 'pokemon_with_stats' do |expected|
  # expected example: { hp: 100, atk: 10, def: 10, sp_atk: 10, sp_def: 10, spd: 10 }
  it 'has the correct calculated stats' do
    aggregate_failures do
      expect(subject.hp_stat).to eq(expected[:hp]) if expected.key?(:hp)
      expect(subject.atk_stat).to eq(expected[:atk]) if expected.key?(:atk)
      expect(subject.def_stat).to eq(expected[:def]) if expected.key?(:def)
      expect(subject.sp_atk_stat).to eq(expected[:sp_atk]) if expected.key?(:sp_atk)
      expect(subject.sp_def_stat).to eq(expected[:sp_def]) if expected.key?(:sp_def)
      expect(subject.spd_stat).to eq(expected[:spd]) if expected.key?(:spd)
    end
  end
end
