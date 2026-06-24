# frozen_string_literal: true

FactoryBot.define do
  factory :battle do
    association :field
    battle_type { 'single' }
    turn { 0 }
    status { 'not_started' }
    sequence(:external_id) { |n| "battle-ext-#{n}" }
  end
end
