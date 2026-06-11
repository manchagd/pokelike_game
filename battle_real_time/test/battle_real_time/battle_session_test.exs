defmodule BattleRealTime.BattleSessionTest do
  use ExUnit.Case, async: true
  alias BattleRealTime.BattleSession

  setup do
    battle_id = "test_battle_#{System.unique_integer([:positive])}"

    # Start the process dynamically under the supervisor
    {:ok, pid} = DynamicSupervisor.start_child(
      BattleRealTime.BattleSupervisor,
      {BattleSession, battle_id}
    )

    %{battle_id: battle_id, pid: pid}
  end

  test "starts with initial state", %{battle_id: battle_id} do
    assert {:ok, state} = BattleSession.get_state(battle_id)
    assert state.battle_id == battle_id
    assert state.turn == 1
    assert state.phase == "waiting_actions"
    assert MapSet.equal?(state.players, MapSet.new())
    assert state.actions == %{}
  end

  test "registers players", %{battle_id: battle_id} do
    assert :ok = BattleSession.register_player(battle_id, "player_1")
    assert {:ok, state} = BattleSession.get_state(battle_id)
    assert MapSet.member?(state.players, "player_1")

    assert :ok = BattleSession.register_player(battle_id, "player_2")
    assert {:ok, state2} = BattleSession.get_state(battle_id)
    assert MapSet.member?(state2.players, "player_2")
  end

  test "stores action and resolves turn when both players submit", %{battle_id: battle_id} do
    # Register 2 players
    assert :ok = BattleSession.register_player(battle_id, "player_1")
    assert :ok = BattleSession.register_player(battle_id, "player_2")

    # Player 1 submits action
    action1 = %{
      "action" => "attack",
      "move_id" => "tackle",
      "player_id" => "player_1",
      "battle_id" => battle_id,
      "targets" => ["player_2"]
    }
    assert {:ok, :pending} = BattleSession.submit_action(battle_id, "player_1", action1)

    assert {:ok, state} = BattleSession.get_state(battle_id)
    assert state.turn == 1
    assert state.actions["player_1"] == action1

    # Subscribe to PubSub to receive the broadcasted state update
    Phoenix.PubSub.subscribe(BattleRealTime.PubSub, "battle_events:#{battle_id}")

    # Player 2 submits action -> resolves turn!
    action2 = %{
      "action" => "switch",
      "monster_id" => "pikachu",
      "player_id" => "player_2",
      "battle_id" => battle_id
    }
    assert {:ok, :resolved} = BattleSession.submit_action(battle_id, "player_2", action2)

    # Check state updated (turn advanced, actions cleared)
    assert {:ok, state2} = BattleSession.get_state(battle_id)
    assert state2.turn == 2
    assert state2.actions == %{}

    # Check broadcast received
    assert_receive {:battle_event, %{event: "battle_state", payload: payload}}
    assert payload["turn"] == 2
    assert payload["log"] == ["Acciones procesadas. ¡Comienza el turno 2!"]
  end
end
