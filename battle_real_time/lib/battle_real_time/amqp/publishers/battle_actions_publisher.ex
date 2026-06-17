defmodule BattleRealTime.AMQP.Publishers.BattleActionsPublisher do
  @moduledoc """
  Publishes player action messages to the `battle_actions` RabbitMQ queue.
  battle_engine consumes from this queue and applies business logic.
  """
  use BattleRealTime.AMQP.Publisher, queue: "battle_actions"

  alias BattleRealTime.Contracts.Publishers.BattleActions.TurnActionsContract
  alias BattleRealTime.Contracts.Publishers.BattleActions.MutateBattleStatusContract
  alias BattleRealTime.Contracts.Publishers.BattleActions.BattleSyncContract
  alias BattleRealTime.Contracts.Publishers.BattleActions.SelectLeadsContract

  @impl true
  def validate("turn_actions", payload), do: TurnActionsContract.validate(payload)
  def validate("mutate_battle_status", payload), do: MutateBattleStatusContract.validate(payload)
  def validate("battle_sync", payload), do: BattleSyncContract.validate(payload)
  def validate("select_leads", payload), do: SelectLeadsContract.validate(payload)
  def validate(action, payload), do: super(action, payload)
end
