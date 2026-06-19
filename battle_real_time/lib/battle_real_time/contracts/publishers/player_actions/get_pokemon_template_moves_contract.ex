defmodule BattleRealTime.Contracts.Publishers.PlayerActions.GetPokemonTemplateMovesContract do
  @moduledoc """
  Validates the payload for the get_pokemon_template_moves player action, under the player_actions queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:player_id, :string)
    field(:pokemon_template_id, :integer)
    field(:timestamp, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :pokemon_template_id, :timestamp])
    |> validate_required([:player_id, :pokemon_template_id])
  end
end
