defmodule BattleRealTime.Contracts.Consumers.PlayerEvents.PokemonTemplatesListContract do
  @moduledoc """
  Validates the payload for the `pokemon_templates_list` event on the `player_events` queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:player_id, :integer)
    field(:timestamp, :string)

    embeds_many :pokemon_templates, PokemonTemplateItem, primary_key: false do
      field(:id, :integer)
      field(:name, :string)
      field(:types, {:array, :string})
      field(:stats, :map)
      field(:sprite, :string)
    end
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :timestamp])
    |> validate_required([:player_id])
    |> cast_embed(:pokemon_templates, with: &pokemon_template_changeset/2)
  end

  defp pokemon_template_changeset(struct, params) do
    struct
    |> cast(params, [:id, :name, :types, :stats, :sprite])
    |> validate_required([:id, :name, :types, :stats])
  end
end
