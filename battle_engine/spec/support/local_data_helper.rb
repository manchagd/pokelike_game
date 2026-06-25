# frozen_string_literal: true

require 'json'

module Spec
  module Support
    module LocalDataHelper
      module_function

      def pokemon_templates
        @pokemon_templates ||= begin
          local_dir = File.expand_path('../../local_data', __dir__)
          standard_path = File.join(local_dir, 'pokemon.json')
          custom_path = File.join(local_dir, 'pokemon_custom.json')

          standard = File.exist?(standard_path) ? JSON.parse(File.read(standard_path)) : []
          custom = File.exist?(custom_path) ? JSON.parse(File.read(custom_path)) : []

          (standard + custom).index_by { |p| p['name'].downcase }
        end
      end

      def moves
        @moves ||= begin
          local_dir = File.expand_path('../../local_data', __dir__)
          standard_path = File.join(local_dir, 'moves.json')
          custom_path = File.join(local_dir, 'moves_custom.json')

          standard = File.exist?(standard_path) ? JSON.parse(File.read(standard_path)) : []
          custom = File.exist?(custom_path) ? JSON.parse(File.read(custom_path)) : []

          (standard + custom).index_by { |m| m['name'].downcase }
        end
      end

      def clean_factory_name(name)
        name.to_s.downcase.gsub(/[^a-z0-9_]/, '_').squeeze('_').gsub(/^_|_$/, '')
      end
    end
  end
end
