defmodule BattleRealTime.Contracts.Consumers.PlayerEvents.BattleJoinedContract do
  @moduledoc """
  Validates the payload for the `battle_joined` event on the `player_events` queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:player_id, :integer)
    field(:battle_id, :string)
    field(:timestamp, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :battle_id, :timestamp])
    |> validate_required([:player_id, :battle_id])
  end
end
