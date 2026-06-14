defmodule BattleRealTime.Players.PlayersUseCasesTest do
  use ExUnit.Case, async: true
  alias BattleRealTime.Players.RegisterPlayer
  alias BattleRealTime.Players.CreateBattle
  alias BattleRealTime.Players.JoinBattle

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
      assert {:ok, payload} = CreateBattle.call("101", 123)
      assert payload["player_id"] == "101"
      assert payload["team_id"] == 123
    end

    test "returns error for empty player" do
      assert {:error, :invalid_player} = CreateBattle.call("", 123)
      assert {:error, :invalid_player} = CreateBattle.call(nil, 123)
    end

    test "returns {:error, errors} if contract validation fails" do
      assert {:error, errors} = CreateBattle.call("non_numeric_player_id", 123)
      assert errors.player_id == ["is invalid"]
    end
  end

  describe "JoinBattle" do
    test "returns {:ok, payload} for valid player ID and battle" do
      assert {:ok, payload} = JoinBattle.call("101", "battle_123", 456)
      assert payload["player_id"] == "101"
      assert payload["battle_id"] == "battle_123"
      assert payload["team_id"] == 456
    end

    test "returns error for empty player" do
      assert {:error, :invalid_player} = JoinBattle.call("", "battle_123")
      assert {:error, :invalid_player} = JoinBattle.call(nil, "battle_123")
    end

    test "returns error for empty battle" do
      assert {:error, :invalid_battle} = JoinBattle.call("101", "")
      assert {:error, :invalid_battle} = JoinBattle.call("101", nil)
    end

    test "returns {:error, errors} if contract validation fails" do
      assert {:error, errors} = JoinBattle.call("non_numeric_player_id", "battle_123", 456)
      assert errors.player_id == ["is invalid"]
    end
  end
end
