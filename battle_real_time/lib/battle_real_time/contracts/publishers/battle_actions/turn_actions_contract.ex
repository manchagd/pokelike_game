defmodule BattleRealTime.Contracts.Publishers.BattleActions.TurnActionsContract do
  @moduledoc """
  Validates the consolidates turn_actions published to RabbitMQ.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:battle_id, :string)
    field(:turn, :integer)
    field(:timestamp, :string)

    embeds_many :actions, ActionItem, primary_key: false do
      field(:action, :string)
      field(:player_id, :integer)
      field(:move_id, :integer)
      field(:pokemon_id, :integer)
      field(:targets, {:array, :string})
    end
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:battle_id, :turn, :timestamp])
    |> validate_required([:battle_id, :turn])
    |> cast_embed(:actions, required: true, with: &action_item_changeset/2)
  end

  defp action_item_changeset(struct, params) do
    struct
    |> cast(params, [:action, :player_id, :move_id, :pokemon_id, :targets])
    |> validate_required([:action, :player_id])
    |> validate_action_fields()
  end

  defp validate_action_fields(changeset) do
    action = get_field(changeset, :action)

    case action do
      "attack" ->
        changeset
        |> validate_required([:move_id, :targets])

      "switch" ->
        changeset
        |> validate_required([:pokemon_id])

      _ ->
        add_error(changeset, :action, "must be either 'attack' or 'switch'")
    end
  end
end
