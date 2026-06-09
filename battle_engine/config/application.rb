# frozen_string_literal: true

module BattleEngine
  module App
    module_function

    @childrens = []

    def register_workers!(childrens: [])
      @childrens = childrens
    end

    def start_workers!
      workers = @childrens.map do |consumer|
        Thread.new {
          BattleEngine.logger.debug("[App] Starting consumer: #{consumer}")
          consumer.new.start
        }
      end

      workers.each(&:join)
    end
  end
end