# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    association :player
    sequence(:name) { |n| "Team #{n}" }
  end
end
