defmodule BattleRealTime.Contracts.Consumers.BattleEvents.MutateBattleStatusContract do
  @moduledoc """
  Validates the payload for the `mutate_battle_status` event on the `battle_events` queue.
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
    |> validate_inclusion(:status, ["not_started", "setting_up", "in_progress", "finished"])
  end
end
