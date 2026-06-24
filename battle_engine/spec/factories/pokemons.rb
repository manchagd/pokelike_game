# frozen_string_literal: true

FactoryBot.define do
  factory :pokemon do
    association :pokemon_template
    nickname { 'Poke' }
    gender { 'Male' }
    nature { 'Hardy' }
    weight { 10.0 }
    lvl { 50 }
    ivs { { 'hp' => 31, 'atk' => 31, 'def' => 31, 'sp_atk' => 31, 'sp_def' => 31, 'spd' => 31 } }
    evs { { 'hp' => 0, 'atk' => 0, 'def' => 0, 'sp_atk' => 0, 'sp_def' => 0, 'spd' => 0 } }
    teratype { 'Normal' }
  end

  # Dynamically define factories for all Pokémon in local data
  Spec::Support::LocalDataHelper.pokemon_templates.each do |_key, data|
    clean_name = Spec::Support::LocalDataHelper.clean_factory_name(data['name'])
    factory_name = clean_name.to_sym
    template_factory_name = "#{clean_name}_template".to_sym

    next if FactoryBot.factories.registered?(factory_name)

    factory factory_name, parent: :pokemon do
      association :pokemon_template, factory: template_factory_name
      nickname { data['name'].truncate(10, omission: '') } # Nickname must be <= 10 characters
      weight { data['weight'] || 10.0 }
      teratype { data['types']&.first || 'Normal' }
    end
  end
end
