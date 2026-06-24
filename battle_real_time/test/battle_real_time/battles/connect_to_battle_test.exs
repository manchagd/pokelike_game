defmodule BattleRealTime.Battles.ConnectToBattleTest do
  use ExUnit.Case, async: true
  alias BattleRealTime.Battles.ConnectToBattle
  alias BattleRealTime.BattleSession

  setup do
    battle_id = "test_battle_#{System.unique_integer([:positive])}"
    %{battle_id: battle_id}
  end

  test "starts a new battle session and registers player", %{battle_id: battle_id} do
    # Ensure not running
    assert BattleRealTime.BattleSession.Supervisor.find_session(battle_id) == {:error, :not_found}

    # Connect to battle
    assert {:ok, %{battle_id: ^battle_id}} = ConnectToBattle.call(battle_id, "player_1", "Ash")

    # Verify Registry has the session
    assert {:ok, pid} = BattleRealTime.BattleSession.Supervisor.find_session(battle_id)
    assert Process.alive?(pid)

    # Verify player registered
    assert {:ok, state} = BattleSession.get_state(battle_id)
    assert MapSet.member?(state.players, "player_1")
  end

  test "uses existing battle session if already started", %{battle_id: battle_id} do
    # Start it manually
    {:ok, pid} = BattleRealTime.BattleSession.Supervisor.start_session(battle_id)

    # Connect to battle
    assert {:ok, %{battle_id: ^battle_id}} = ConnectToBattle.call(battle_id, "player_2", "Misty")

    # Verify Registry still has the same pid
    assert {:ok, ^pid} = BattleRealTime.BattleSession.Supervisor.find_session(battle_id)

    # Verify player registered
    assert {:ok, state} = BattleSession.get_state(battle_id)
    assert MapSet.member?(state.players, "player_2")
  end
end
