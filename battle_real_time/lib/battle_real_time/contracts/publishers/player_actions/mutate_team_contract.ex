defmodule BattleRealTime.Contracts.Publishers.PlayerActions.MutateTeamContract do
  @moduledoc """
  Validates the payload for the mutate_team player action, under the player_actions queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:player_id, :string)
    field(:name, :string)
    field(:timestamp, :string)
    field(:team_id, :integer)

    embeds_many :pokemons, PokemonItem, primary_key: false do
      field(:pokemon_template_id, :integer)
      field(:nickname, :string)
      field(:nature, :string)
      field(:gender, :string)
      field(:ivs, :map)
      field(:evs, :map)
      field(:moves, {:array, :integer})
    end
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :name, :timestamp, :team_id])
    |> validate_required([:player_id, :name, :pokemons])
    |> cast_embed(:pokemons, required: true, with: &pokemon_changeset/2)
  end

  defp pokemon_changeset(struct, params) do
    struct
    |> cast(params, [:pokemon_template_id, :nickname, :nature, :gender, :ivs, :evs, :moves])
    |> validate_required([:pokemon_template_id, :moves])
  end
end
