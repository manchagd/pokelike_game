defmodule BattleRealTime.Contracts.Publishers.PlayerActions.RegisterContractTest do
  use ExUnit.Case, async: true
  alias BattleRealTime.Contracts.Publishers.PlayerActions.RegisterContract

  describe "validate/1" do
    test "returns {:ok, map} with valid parameters" do
      params = %{"name" => "Ash"}
      assert {:ok, %{name: "Ash"}} = RegisterContract.validate(params)
    end

    test "returns {:error, changeset} with missing name" do
      params = %{}
      assert {:error, changeset} = RegisterContract.validate(params)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns {:error, changeset} with invalid types" do
      params = %{"name" => 123}
      assert {:error, changeset} = RegisterContract.validate(params)
      assert %{name: ["is invalid"]} = errors_on(changeset)
    end
  end

  # Helper to extract Ecto errors
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
