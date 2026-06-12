defmodule BattleRealTime.AMQP.Publishers.PlayerActionsPublisher do
  @moduledoc """
  Publishes player action messages to the `player_actions` RabbitMQ queue.
  """
  use BattleRealTime.AMQP.Publisher, queue: "player_actions"

  alias BattleRealTime.Contracts.Publishers.PlayerActions.RegisterContract
  alias BattleRealTime.Contracts.Publishers.PlayerActions.CreateBattleContract
  alias BattleRealTime.Contracts.Publishers.PlayerActions.JoinBattleContract

  @impl true
  def validate("register", payload), do: RegisterContract.validate(payload)
  def validate("create_battle", payload), do: CreateBattleContract.validate(payload)
  def validate("join_battle", payload), do: JoinBattleContract.validate(payload)
  def validate(action, payload), do: super(action, payload)
end
