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
  end
end
