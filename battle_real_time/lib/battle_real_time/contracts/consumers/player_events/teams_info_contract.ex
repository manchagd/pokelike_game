defmodule BattleRealTime.Contracts.Consumers.PlayerEvents.TeamsInfoContract do
  @moduledoc """
  Validates the payload for the `teams_info` event on the `player_events` queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:player_id, :integer)
    field(:timestamp, :string)

    embeds_many :teams, TeamItem, primary_key: false do
      field(:id, :integer)
      field(:name, :string)

      embeds_many :pokemons, PokemonItem, primary_key: false do
        field(:name, :string)
        field(:types, {:array, :string})
      end
    end
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :timestamp])
    |> validate_required([:player_id])
    |> cast_embed(:teams, with: &team_changeset/2)
  end

  defp team_changeset(struct, params) do
    struct
    |> cast(params, [:id, :name])
    |> validate_required([:id, :name])
    |> cast_embed(:pokemons, with: &pokemon_changeset/2)
  end

  defp pokemon_changeset(struct, params) do
    struct
    |> cast(params, [:name, :types])
    |> validate_required([:name, :types])
  end
end
