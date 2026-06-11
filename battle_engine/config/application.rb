# frozen_string_literal: true

module BattleEngine
  module App
    class Application
      def initialize
        @children = []
      end

      def register_workers!(children = [])
        @children = children
      end

      def start!
        workers = @children.map do |consumer|
          BattleEngine.logger.debug("[App] Starting consumer: #{consumer}")
          Thread.new do
            consumer.new.start
          end
        end

        workers.each(&:join)
      end
    end

    module_function

    def init!
      application = Application.new

      yield application
      BattleEngine.logger.debug("[App] Starting workers...")

      application.start!
    end
  end
end