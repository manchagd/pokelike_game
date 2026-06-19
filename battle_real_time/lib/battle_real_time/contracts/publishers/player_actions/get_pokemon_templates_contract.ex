defmodule BattleRealTime.Contracts.Publishers.PlayerActions.GetPokemonTemplatesContract do
  @moduledoc """
  Validates the payload for the get_pokemon_templates player action, under the player_actions queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:player_id, :string)
    field(:timestamp, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :timestamp])
    |> validate_required([:player_id])
  end
end
