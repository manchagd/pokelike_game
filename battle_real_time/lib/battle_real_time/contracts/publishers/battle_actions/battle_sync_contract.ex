defmodule BattleRealTime.Contracts.Publishers.BattleActions.BattleSyncContract do
  @moduledoc """
  Validates the battle_sync payload published to RabbitMQ.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:battle_id, :string)
    field(:timestamp, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:battle_id, :timestamp])
    |> validate_required([:battle_id])
  end
end
