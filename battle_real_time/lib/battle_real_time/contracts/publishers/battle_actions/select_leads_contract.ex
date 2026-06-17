defmodule BattleRealTime.Contracts.Publishers.BattleActions.SelectLeadsContract do
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:battle_id, :string)

    embeds_many :players, PlayerLead, primary_key: false do
      field(:player_id, :string)
      field(:lead, :integer)
    end
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:battle_id])
    |> cast_embed(:players, required: true, with: &player_lead_changeset/2)
    |> validate_required([:battle_id])
  end

  defp player_lead_changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :lead])
    |> validate_required([:player_id, :lead])
  end
end
