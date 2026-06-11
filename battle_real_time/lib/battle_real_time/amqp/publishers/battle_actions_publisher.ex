defmodule BattleRealTime.AMQP.Publishers.BattleActionsPublisher do
  @moduledoc """
  Publishes player action messages to the `battle_actions` RabbitMQ queue.
  battle_engine consumes from this queue and applies business logic.
  """
  use BattleRealTime.AMQP.Publisher, queue: "battle_actions"

  @impl true
  def validate("turn_actions", _payload) do
    {:error, %Ecto.Changeset{action: :validate}}
  end

  def validate(_action, payload) do
    # Temporarily permit all battle actions until contracts are written
    {:ok, payload}
  end
end
