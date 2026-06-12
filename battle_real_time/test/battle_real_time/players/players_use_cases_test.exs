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
    test "returns {:ok, payload} for a valid player" do
      assert {:ok, payload} = CreateBattle.call("player_1")
      assert payload["player_id"] == "player_1"
      assert payload["team_id"] == 1
    end

    test "returns error for empty player" do
      assert {:error, :invalid_player} = CreateBattle.call("")
      assert {:error, :invalid_player} = CreateBattle.call(nil)
    end
  end

  describe "RequestJoinBattle" do
    test "returns {:ok, payload} for valid player and battle" do
      assert {:ok, payload} = RequestJoinBattle.call("player_1", "battle_123")
      assert payload["player_id"] == "player_1"
      assert payload["battle_id"] == "battle_123"
      assert payload["team_id"] == 1
    end

    test "returns error for empty player" do
      assert {:error, :invalid_player} = RequestJoinBattle.call("", "battle_123")
      assert {:error, :invalid_player} = RequestJoinBattle.call(nil, "battle_123")
    end

    test "returns error for empty battle" do
      assert {:error, :invalid_battle} = RequestJoinBattle.call("player_1", "")
      assert {:error, :invalid_battle} = RequestJoinBattle.call("player_1", nil)
    end
  end
end
