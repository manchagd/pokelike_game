defmodule BattleRealTime.Battles.ForfeitTest do
  use ExUnit.Case, async: true
  alias BattleRealTime.Battles.Forfeit
  alias BattleRealTime.BattleSession

  setup do
    battle_id = "test_battle_#{System.unique_integer([:positive])}"

    {:ok, pid} = BattleRealTime.BattleSession.Supervisor.start_session(battle_id)

    # Sync first to transition out of :syncing
    :ok = BattleSession.sync_state(battle_id, %{"turn" => 1, "status" => "not_started"})
    :ok = BattleSession.register_player(battle_id, "player_1", "Ash")

    %{battle_id: battle_id, pid: pid}
  end

  test "forfeits battle but does not stop session until engine confirms", %{
    battle_id: battle_id,
    pid: pid
  } do
    # Subscribe to events to avoid block/warning
    Phoenix.PubSub.subscribe(BattleRealTime.PubSub, "battle_events:#{battle_id}")

    assert :ok = Forfeit.call(battle_id, "player_1")

    # Session is still alive because it expects engine to trigger termination
    assert Process.alive?(pid)

    # Simulate engine confirming termination via terminate_session call
    assert :ok = BattleSession.terminate_session(battle_id, "El jugador Ash se rinde.")

    # Verify session is terminated now
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
