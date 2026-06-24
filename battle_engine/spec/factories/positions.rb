# frozen_string_literal: true

FactoryBot.define do
  factory :position do
    association :field
    association :pokemon_snapshot, factory: :snorlax_snapshot
    group { 1 }
    side { 'A' }
  end
end
