defmodule BattleRealTime.Contracts.Consumers.BattleEvents.BattleStatusContract do
  @moduledoc """
  Validates the payload for the `battle_status` event on the `battle_events` queue.
  """
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:external_id, :string)
    field(:status, :string)
    field(:turn, :integer)
    field(:timestamp, :string)

    embeds_many :players, Player, primary_key: false do
      field(:id, :integer)
      field(:name, :string)
      field(:team, :string)

      embeds_many :pokemons, Pokemon, primary_key: false do
        field(:id, :integer)
        field(:hp, :integer)
        field(:max_hp, :integer)
        field(:level, :integer)
        field(:lead, :boolean)
        field(:name, :string)
        field(:pokemon_name, :string)
        field(:types, {:array, :string})
        field(:sprite_url, :string)
        field(:status_condition, :map)
        field(:stat_stages, :map)
        field(:turn_afflictions, :map)
        field(:locked_condition, :map)
        field(:attack_log, {:array, :map})

        embeds_one :field_position, FieldPosition, primary_key: false do
          field(:group, :integer)
          field(:side, :string)
        end

        embeds_many :attacks, Attack, primary_key: false do
          field(:id, :integer)
          field(:name, :string)
          field(:power, :integer)
          field(:accuracy, :integer)
          field(:pp, :integer)
          field(:category, :string)
          field(:types, {:array, :string})

          embeds_one :meta, Meta, primary_key: false do
            field(:enforce_switch, :boolean)
          end
        end
      end
    end
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:external_id, :status, :turn, :timestamp])
    |> cast_embed(:players, required: false, with: &player_changeset/2)
    |> validate_required([:external_id, :status, :turn])
  end

  # --- Embedded Changesets ---

  def player_changeset(struct, params) do
    struct
    |> cast(params, [:id, :name, :team])
    |> cast_embed(:pokemons, required: false, with: &pokemon_changeset/2)
    |> validate_required([:id, :name, :team])
  end

  def pokemon_changeset(struct, params) do
    struct
    |> cast(params, [
      :id,
      :hp,
      :max_hp,
      :level,
      :lead,
      :name,
      :pokemon_name,
      :types,
      :sprite_url,
      :status_condition,
      :stat_stages,
      :turn_afflictions,
      :locked_condition,
      :attack_log
    ])
    |> cast_embed(:field_position, required: false, with: &field_position_changeset/2)
    |> cast_embed(:attacks, required: false, with: &attack_changeset/2)
    |> validate_required([:id, :hp, :max_hp, :level, :lead, :name, :pokemon_name, :types])
  end

  def field_position_changeset(struct, params) do
    struct
    |> cast(params, [:group, :side])
    |> validate_required([:group, :side])
  end

  def attack_changeset(struct, params) do
    struct
    |> cast(params, [:id, :name, :power, :accuracy, :pp, :types, :category])
    |> cast_embed(:meta, required: false, with: &meta_changeset/2)
    |> validate_required([:id, :name, :pp, :types, :category])
  end

  def meta_changeset(struct, params) do
    struct
    |> cast(params, [:enforce_switch])
  end
end
