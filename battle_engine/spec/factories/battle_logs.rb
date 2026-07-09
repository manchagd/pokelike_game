# frozen_string_literal: true

FactoryBot.define do
  factory :battle_log do
    association :battle
    message { 'Un ataque fulminante ha ocurrido.' }
  end
end
