defmodule BattleRealTime.Contracts.Publishers.PlayerActions.CreateBattleContract do
  @moduledoc """
  Validates the payload for the create_battle player action, under the player_actions queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:player_id, :integer)
    field(:team_id, :integer)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :team_id])
    |> validate_required([:player_id, :team_id])
  end
end
