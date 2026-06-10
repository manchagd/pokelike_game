defmodule BattleRealTime.Contracts.Contract do
  @moduledoc """
  Base module to implement Ecto validation contracts.
  Automatically sets up the schema, changeset imports, and provides
  a default validation workflow that returns plain maps.
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @doc """
      Validates parameters against the schema, applying the changeset validation,
      and converting the result to a plain map.
      """
      @spec validate(map()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
      def validate(params) do
        changeset(struct(__MODULE__), params)
        |> apply_action(:validate)
        |> normalize()
      end

      defp normalize({:ok, struct}), do: {:ok, to_plain_map(struct)}
      defp normalize({:error, changeset}), do: {:error, changeset}

      # Helper recursively converting structs/maps/lists to plain maps
      defp to_plain_map(struct) when is_struct(struct) do
        struct
        |> Map.from_struct()
        |> Map.delete(:__meta__)
        |> to_plain_map()
      end

      defp to_plain_map(map) when is_map(map) do
        Map.new(map, fn {k, v} -> {k, to_plain_map(v)} end)
      end

      defp to_plain_map(list) when is_list(list) do
        Enum.map(list, &to_plain_map/1)
      end

      defp to_plain_map(other), do: other

      defoverridable validate: 1
    end
  end
end
