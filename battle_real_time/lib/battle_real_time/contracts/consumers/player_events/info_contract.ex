defmodule BattleRealTime.Contracts.Consumers.PlayerEvents.InfoContract do
  @moduledoc """
  Validates the payload for the `info` event on the `player_events` queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    embeds_one :player, Player, primary_key: false do
      field :id, :integer
      field :name, :string
      field :team, :string

      embeds_many :teams, Team, primary_key: false do
        field :name, :string
        field :description, :string

        embeds_many :monsters, Monster, primary_key: false do
          field :name, :string
          field :color, :string
        end
      end

      embeds_one :battle_history, BattleHistory, primary_key: false do
        field :victories, :integer
        field :defeats, :integer
        field :history, {:array, :string}
      end
    end

    embeds_many :battles, Battle, primary_key: false do
      field :id, :integer

      embeds_many :opponent, Opponent, primary_key: false do
        field :name, :string
        field :team, :string
      end
    end
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [])
    |> cast_embed(:player, required: true, with: &player_changeset/2)
    |> cast_embed(:battles, with: &battle_changeset/2)
  end

  # --- Embedded Changesets ---

  def player_changeset(struct, params) do
    struct
    |> cast(params, [:id, :name, :team])
    |> validate_required([:id, :name])
    |> cast_embed(:teams, with: &team_changeset/2)
    |> cast_embed(:battle_history, required: true, with: &battle_history_changeset/2)
  end

  def team_changeset(struct, params) do
    struct
    |> cast(params, [:name, :description])
    |> validate_required([:name])
    |> cast_embed(:monsters, with: &monster_changeset/2)
  end

  def monster_changeset(struct, params) do
    struct
    |> cast(params, [:name, :color])
    |> validate_required([:name])
  end

  def battle_history_changeset(struct, params) do
    struct
    |> cast(params, [:victories, :defeats, :history])
    |> validate_required([:victories, :defeats])
  end

  def battle_changeset(struct, params) do
    struct
    |> cast(params, [:id])
    |> validate_required([:id])
    |> cast_embed(:opponent, with: &opponent_changeset/2)
  end

  def opponent_changeset(struct, params) do
    struct
    |> cast(params, [:name, :team])
    |> validate_required([:name])
  end
end
