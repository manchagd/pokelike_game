defmodule BattleRealTime.Contracts.Publishers.RegisterContract do
  @moduledoc """
  Validates the payload for the register player action.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:name, :string)
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, [:name])
    |> validate_required([:name])
    |> apply_action(:validate)
  end

  def validate(params) do
    changeset(params)
    |> normalize()
  end

  defp normalize({:ok, struct}), do: {:ok, Map.from_struct(struct)}
  defp normalize(params), do: params
end
