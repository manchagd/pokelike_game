defmodule BattleRealTime.Contracts.Publishers.PlayerActions.JoinBattleContract do
  @moduledoc """
  Validates the payload for the join_battle player action, under the player_actions queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:player_id, :integer)
    field(:battle_id, :string)
    field(:team_id, :integer)
    field(:timestamp, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :battle_id, :team_id, :timestamp])
    |> validate_required([:player_id, :battle_id, :team_id])
  end
end
