defmodule BattleRealTime.Contracts.RegisterContract do
  @moduledoc """
  Validates the payload for the register player action.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
  end

  @doc """
  Validates the input parameters. Returns `{:ok, validated_map}` or `{:error, changeset}`.
  """
  def validate(params) do
    %__MODULE__{}
    |> cast(params, [:name])
    |> validate_required([:name])
    |> apply_action(:insert)
    |> case do
      {:ok, struct} -> {:ok, Map.from_struct(struct)}
      {:error, changeset} -> {:error, changeset}
    end
  end
end
