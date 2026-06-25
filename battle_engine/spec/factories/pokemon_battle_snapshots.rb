# frozen_string_literal: true

FactoryBot.define do
  factory :pokemon_battle_snapshot do
    association :pokemon
    association :battle
    association :player
    hp { pokemon.stats['hp'] || 100 }
    status_condition { {} }
    stat_stages { {} }
    turn_afflictions { {} }
    locked_condition { {} }
    attack_log { [] }
  end

  # Dynamically define snapshot factories for all Pokémon in local data
  Spec::Support::LocalDataHelper.pokemon_templates.each_value do |data|
    clean_name = Spec::Support::LocalDataHelper.clean_factory_name(data['name'])
    factory_name = :"#{clean_name}_snapshot"
    pokemon_factory_name = clean_name.to_sym

    next if FactoryBot.factories.registered?(factory_name)

    factory factory_name, parent: :pokemon_battle_snapshot do
      association :pokemon, factory: pokemon_factory_name
    end
  end
end
