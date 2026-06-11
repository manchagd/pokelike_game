defmodule BattleRealTime.AMQP.Publishers.BattleActionsPublisher do
  @moduledoc """
  Publishes player action messages to the `battle_actions` RabbitMQ queue.
  battle_engine consumes from this queue and applies business logic.
  """
  use BattleRealTime.AMQP.Publisher, queue: "battle_actions"

  alias BattleRealTime.Contracts.Publishers.BattleActions.TurnActionsContract
  alias BattleRealTime.Contracts.Publishers.BattleActions.TerminateBattleContract

  @impl true
  def validate("turn_actions", payload) do
    TurnActionsContract.validate(payload)
  end

  def validate("terminate_battle", payload) do
    TerminateBattleContract.validate(payload)
  end

  def validate(action, payload), do: super(action, payload)
end
