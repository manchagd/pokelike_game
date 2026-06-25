# frozen_string_literal: true

FactoryBot.define do
  factory :move do
    name { 'Dummy Move' }
    type { 'Normal' }
    category { 'Physical' }
    pp { 35 }
    power { 40 }
    accuracy { 100 }
    handler { :damage }

    initialize_with { Move.find_or_initialize_by(name: name) }
  end

  # Dynamically define factories for all moves in local data
  Spec::Support::LocalDataHelper.moves.each_value do |data|
    clean_name = Spec::Support::LocalDataHelper.clean_factory_name(data['name'])
    factory_name = clean_name.to_sym

    next if FactoryBot.factories.registered?(factory_name)

    factory factory_name, parent: :move do
      name { data['name'] }
      type { data['type'] || 'Normal' }
      secondary_type { data['secondary_type'] }
      category { data['category'] || 'Physical' }
      pp { data['pp'] || 35 }
      power { data['power'] }
      accuracy { data['accuracy'] }
      handler { (data['handler'] || 'damage').underscore.to_sym }
      pokeapi_id { data['pokeapi_id'] }
      meta { data['meta'] || {} }
    end
  end
end
