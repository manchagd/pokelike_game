defmodule BattleRealTime.Contracts.Publishers.PlayerActions.RegisterContract do
  @moduledoc """
  Validates the payload for the register player action, under the player_actions queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:name, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
