defmodule BattleRealTime.Contracts.Consumers.PlayerEvents.BattlesInfoContract do
  @moduledoc """
  Validates the payload for the `battles_info` event on the `player_events` queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:player_id, :integer)
    field(:timestamp, :string)

    embeds_many :battles, Battle, primary_key: false do
      field(:id, :string)

      embeds_many :players, PlayerInfo, primary_key: false do
        field(:name, :string)
        field(:team, :string)
      end
    end
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :timestamp])
    |> validate_required([:player_id])
    |> cast_embed(:battles, with: &battle_changeset/2)
  end

  def battle_changeset(struct, params) do
    struct
    |> cast(params, [:id])
    |> validate_required([:id])
    |> cast_embed(:players, with: &player_info_changeset/2)
  end

  def player_info_changeset(struct, params) do
    struct
    |> cast(params, [:name, :team])
    |> validate_required([:name])
  end
end
