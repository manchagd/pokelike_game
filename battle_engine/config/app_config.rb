# frozen_string_literal: true

module AppConfig
  module_function

  def app_env
    ENV.fetch('APP_ENV', 'development')
  end

  def database_url
    ENV.fetch('DATABASE_URL', "postgres://postgres:admin@localhost:5432/battle_engine_#{app_env}")
  end

  def rabbitmq_url
    ENV.fetch('RABBITMQ_URL', 'amqp://guest:admin@localhost:5672')
  end

  def log_level
    ENV.fetch('LOG_LEVEL', 'debug').to_sym
  end
end
