# frozen_string_literal: true

require "active_record"
require_relative "app_config"

module BattleEngine
  module Database
    module_function

    def connect!
      ActiveRecord::Base.establish_connection(AppConfig.database_url)
      ActiveRecord::Base.logger = BattleEngine.logger
    end

    def configuration
      {
        adapter: "postgresql",
        url:     AppConfig.database_url
      }
    end

    def dump_schema!
      require "active_record/schema_dumper"
      schema_file = File.expand_path("../db/schema.rb", __dir__)

      File.open(schema_file, "w:utf-8") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection_pool, file)
      end
      BattleEngine.logger.info("[DB] Schema successfully dumped to db/schema.rb")
    end
  end
end
