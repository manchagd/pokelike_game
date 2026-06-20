defmodule BattleRealTime.Contracts.Consumers.PlayerEvents.PokemonTemplateMovesListContract do
  @moduledoc """
  Validates the payload for the `pokemon_template_moves_list` event on the `player_events` queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:player_id, :integer)
    field(:pokemon_template_id, :integer)
    field(:timestamp, :string)

    embeds_many :moves, MoveItem, primary_key: false do
      field(:id, :integer)
      field(:name, :string)
      field(:type, :string)
      field(:category, :string)
      field(:power, :integer)
      field(:accuracy, :integer)
      field(:pp, :integer)
    end
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :pokemon_template_id, :timestamp])
    |> validate_required([:player_id, :pokemon_template_id])
    |> cast_embed(:moves, with: &move_changeset/2)
  end

  defp move_changeset(struct, params) do
    struct
    |> cast(params, [:id, :name, :type, :category, :power, :accuracy, :pp])
    |> validate_required([:id, :name, :type, :category, :pp])
  end
end
