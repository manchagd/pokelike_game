defmodule BattleRealTime.Contracts.Consumers.PlayerEvents.TeamDetailsContract do
  @moduledoc """
  Validates the payload for the team_details event on the player_events queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:player_id, :integer)
    field(:team_id, :integer)
    field(:name, :string)
    field(:timestamp, :string)

    embeds_many :pokemons, PokemonItem, primary_key: false do
      field(:id, :integer)
      field(:pokemon_template_id, :integer)
      field(:name, :string)
      field(:types, {:array, :string})
      field(:stats, :map)
      field(:nickname, :string)
      field(:gender, :string)
      field(:nature, :string)
      field(:weight, :float)
      field(:lvl, :integer)
      field(:teratype, :string)
      field(:ivs, :map)
      field(:evs, :map)
      field(:sprite, :string)
      field(:selected_moves, {:array, :integer})
    end
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :team_id, :name, :timestamp])
    |> validate_required([:player_id, :team_id, :name])
    |> cast_embed(:pokemons, required: true, with: &pokemon_changeset/2)
  end

  defp pokemon_changeset(struct, params) do
    struct
    |> cast(params, [
      :id,
      :pokemon_template_id,
      :name,
      :types,
      :stats,
      :nickname,
      :gender,
      :nature,
      :weight,
      :lvl,
      :teratype,
      :ivs,
      :evs,
      :sprite,
      :selected_moves
    ])
    |> validate_required([
      :id,
      :pokemon_template_id,
      :name,
      :types,
      :nature,
      :weight,
      :lvl,
      :selected_moves
    ])
  end
end
