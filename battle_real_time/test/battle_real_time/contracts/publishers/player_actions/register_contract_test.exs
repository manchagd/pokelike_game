defmodule BattleRealTime.Contracts.Publishers.PlayerActions.RegisterContractTest do
  use ExUnit.Case, async: true
  alias BattleRealTime.Contracts.Publishers.PlayerActions.RegisterContract
  alias BattleRealTime.Contracts.Contract

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
    Contract.format_errors(changeset)
  end
end
