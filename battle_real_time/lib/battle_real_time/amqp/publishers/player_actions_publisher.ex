defmodule BattleRealTime.AMQP.Publishers.PlayerActionsPublisher do
  @moduledoc """
  Publishes player action messages to the `player_actions` RabbitMQ queue.
  """
  use BattleRealTime.AMQP.Publisher, queue: "player_actions"
end
