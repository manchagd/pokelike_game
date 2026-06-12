defmodule BattleRealTime.Battles.ForfeitTest do
  use ExUnit.Case, async: true
  alias BattleRealTime.Battles.Forfeit
  alias BattleRealTime.BattleSession

  setup do
    battle_id = "test_battle_#{System.unique_integer([:positive])}"

    {:ok, pid} =
      DynamicSupervisor.start_child(
        BattleRealTime.BattleSupervisor,
        {BattleSession, battle_id}
      )

    :ok = BattleSession.register_player(battle_id, "player_1", "Ash")

    %{battle_id: battle_id, pid: pid}
  end

  test "forfeits battle and terminates session", %{battle_id: battle_id, pid: pid} do
    # Subscribe to events to avoid block/warning
    Phoenix.PubSub.subscribe(BattleRealTime.PubSub, "battle_events:#{battle_id}")

    assert :ok = Forfeit.call(battle_id, "player_1")

    # Verify session is terminated
    refute Process.alive?(pid)
  end

  test "returns error with empty player_id", %{battle_id: battle_id} do
    assert {:error, :invalid_player} = Forfeit.call(battle_id, "")
    assert {:error, :invalid_player} = Forfeit.call(battle_id, nil)
  end

  test "returns {:error, :battle_not_found} if battle does not exist" do
    assert {:error, :battle_not_found} = Forfeit.call("non_existent_battle", "player_1")
  end
end
