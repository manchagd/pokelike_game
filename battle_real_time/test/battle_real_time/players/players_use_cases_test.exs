defmodule BattleRealTime.Players.PlayersUseCasesTest do
  use ExUnit.Case, async: true
  alias BattleRealTime.Players.RegisterPlayer
  alias BattleRealTime.Players.CreateBattle
  alias BattleRealTime.Players.RequestJoinBattle

  describe "RegisterPlayer" do
    test "returns :ok for a valid name" do
      assert :ok = RegisterPlayer.call("Ash")
    end

    test "returns error for an empty name" do
      assert {:error, :invalid_player_name} = RegisterPlayer.call("")
      assert {:error, :invalid_player_name} = RegisterPlayer.call("  ")
      assert {:error, :invalid_player_name} = RegisterPlayer.call(nil)
    end
  end

  describe "CreateBattle" do
    test "returns {:ok, payload} for a valid player ID" do
      assert {:ok, payload} = CreateBattle.call("101")
      assert payload["player_id"] == "101"
      assert payload["team_id"] == 1
    end

    test "returns error for empty player" do
      assert {:error, :invalid_player} = CreateBattle.call("")
      assert {:error, :invalid_player} = CreateBattle.call(nil)
    end

    test "returns {:error, errors} if contract validation fails" do
      assert {:error, errors} = CreateBattle.call("non_numeric_player_id")
      assert errors.player_id == ["is invalid"]
    end
  end

  describe "RequestJoinBattle" do
    test "returns {:ok, payload} for valid player ID and battle" do
      assert {:ok, payload} = RequestJoinBattle.call("101", "battle_123")
      assert payload["player_id"] == "101"
      assert payload["battle_id"] == "battle_123"
      assert payload["team_id"] == 1
    end

    test "returns error for empty player" do
      assert {:error, :invalid_player} = RequestJoinBattle.call("", "battle_123")
      assert {:error, :invalid_player} = RequestJoinBattle.call(nil, "battle_123")
    end

    test "returns error for empty battle" do
      assert {:error, :invalid_battle} = RequestJoinBattle.call("101", "")
      assert {:error, :invalid_battle} = RequestJoinBattle.call("101", nil)
    end

    test "returns {:error, errors} if contract validation fails" do
      assert {:error, errors} = RequestJoinBattle.call("non_numeric_player_id", "battle_123")
      assert errors.player_id == ["is invalid"]
    end
  end
end
