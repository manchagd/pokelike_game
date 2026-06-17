defmodule BattleRealTime.Contracts.Publishers.BattleActions.MutateBattleStatusContract do
  @moduledoc """
  Validates the mutate_battle_status payload published to RabbitMQ.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:battle_id, :string)
    field(:status, :string)
    field(:reason, :string)
    field(:timestamp, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:battle_id, :status, :reason, :timestamp])
    |> validate_required([:battle_id, :status])
  end
end
