defmodule BattleRealTime.AMQP.Publishers.PlayerActionsPublisher do
  @moduledoc """
  Publishes player action messages to the `player_actions` RabbitMQ queue.
  """
  use BattleRealTime.AMQP.Publisher, queue: "player_actions"

  @impl true
  def validate("register", payload) do
    BattleRealTime.Contracts.Publishers.PlayerActions.RegisterContract.validate(payload)
  end

  def validate(action, payload), do: super(action, payload)
end
