defmodule BattleRealTime.Contracts.Publishers.PlayerActions.RegisterContract do
  @moduledoc """
  Validates the payload for the register player action, under the player_actions queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:name, :string)
    field(:timestamp, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :timestamp])
    |> validate_required([:name])
  end
end
