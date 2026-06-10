defmodule BattleRealTime.AMQP.Publishers.PlayerActionsPublisher do
  @moduledoc """
  Publishes player action messages to the `player_actions` RabbitMQ queue.
  """
  use BattleRealTime.AMQP.Publisher, queue: "player_actions"

  alias BattleRealTime.Contracts.Publishers.PlayerActions.RegisterContract

  @impl true
  def validate("register", payload) do
    RegisterContract.validate(payload)
  end

  def validate(action, payload), do: super(action, payload)
end
