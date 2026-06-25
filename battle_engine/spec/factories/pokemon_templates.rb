# frozen_string_literal: true

FactoryBot.define do
  factory :pokemon_template do
    name { 'Pikachu' }
    types { ['Electric'] }
    stats { { 'hp' => 35, 'atk' => 55, 'def' => 40, 'sp_atk' => 50, 'sp_def' => 50, 'spd' => 90 } }
    weight { 6.0 }
    gender_rate { 4 }

    initialize_with { PokemonTemplate.find_or_initialize_by(name: name) }
  end

  # Dynamically define factories for all Pokémon templates in local data
  Spec::Support::LocalDataHelper.pokemon_templates.each_value do |data|
    clean_name = Spec::Support::LocalDataHelper.clean_factory_name(data['name'])
    factory_name = :"#{clean_name}_template"

    next if FactoryBot.factories.registered?(factory_name)

    factory factory_name, parent: :pokemon_template do
      name { data['name'] }
      types { data['types'] || ['Normal'] }
      stats { data['stats'] || {} }
      front_sprite { data['front_sprite'] }
      back_sprite { data['back_sprite'] }
      pokeapi_id { data['pokeapi_id'] }
      weight { data['weight'] }
      gender_rate { data['gender_rate'] }
    end
  end
end
