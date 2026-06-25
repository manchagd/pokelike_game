# frozen_string_literal: true

FactoryBot.define do
  factory :battle_player do
    association :battle
    association :player
  end
end
