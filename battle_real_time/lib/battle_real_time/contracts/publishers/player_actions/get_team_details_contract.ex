defmodule BattleRealTime.Contracts.Publishers.PlayerActions.GetTeamDetailsContract do
  @moduledoc """
  Validates the payload for the get_team_details action.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:player_id, :string)
    field(:team_id, :integer)
    field(:timestamp, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :team_id, :timestamp])
    |> validate_required([:player_id, :team_id])
  end
end
