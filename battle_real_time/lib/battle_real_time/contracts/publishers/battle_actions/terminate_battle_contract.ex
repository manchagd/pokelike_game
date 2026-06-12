defmodule BattleRealTime.Contracts.Publishers.BattleActions.TerminateBattleContract do
  @moduledoc """
  Validates the terminate_battle payload published to RabbitMQ.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:battle_id, :string)
    field(:reason, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:battle_id, :reason])
    |> validate_required([:battle_id, :reason])
  end
end
