defmodule BattleRealTime.AMQP.BattleActionsPublisher do
  @moduledoc """
  Publishes player action messages to the `battle_actions` RabbitMQ queue.
  battle_engine consumes from this queue and applies business logic.
  """
  use BattleRealTime.AMQP.Publisher, queue: "battle_actions"
end
