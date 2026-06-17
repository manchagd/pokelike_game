defmodule BattleRealTime.AMQP.Publishers.BattleActionsPublisher do
  @moduledoc """
  Publishes player action messages to the `battle_actions` RabbitMQ queue.
  battle_engine consumes from this queue and applies business logic.
  """
  use BattleRealTime.AMQP.Publisher, queue: "battle_actions"

  alias BattleRealTime.Contracts.Publishers.BattleActions.TurnActionsContract
  alias BattleRealTime.Contracts.Publishers.BattleActions.TerminateBattleContract
  alias BattleRealTime.Contracts.Publishers.BattleActions.BattleSyncContract

  @impl true
  def validate("turn_actions", payload), do: TurnActionsContract.validate(payload)
  def validate("terminate_battle", payload), do: TerminateBattleContract.validate(payload)
  def validate("battle_sync", payload), do: BattleSyncContract.validate(payload)
  def validate(action, payload), do: super(action, payload)
end
