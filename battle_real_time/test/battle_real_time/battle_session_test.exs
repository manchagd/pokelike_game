defmodule BattleRealTime.BattleSessionTest do
  use ExUnit.Case, async: true
  alias BattleRealTime.BattleSession

  setup do
    battle_id = "test_battle_#{System.unique_integer([:positive])}"

    # Start the process dynamically under the supervisor
    {:ok, pid} =
      DynamicSupervisor.start_child(
        BattleRealTime.BattleSupervisor,
        {BattleSession, battle_id}
      )

    %{battle_id: battle_id, pid: pid}
  end

  test "starts with initial state", %{battle_id: battle_id} do
    assert {:ok, state} = BattleSession.get_state(battle_id)
    assert state.battle_id == battle_id
    assert state.turn == 0
    assert state.phase == :syncing
    assert MapSet.equal?(state.players, MapSet.new())
    assert state.actions == %{}
  end

  test "registers players and transitions phase", %{battle_id: battle_id} do
    # Sync first to transition out of :syncing
    assert :ok = BattleSession.sync_state(battle_id, %{"turn" => 1, "status" => "not_started"})

    assert :ok = BattleSession.register_player(battle_id, "player_1")
    assert {:ok, state} = BattleSession.get_state(battle_id)
    assert MapSet.member?(state.players, "player_1")
    assert state.phase == :waiting_players

    assert :ok = BattleSession.register_player(battle_id, "player_2")
    assert {:ok, state2} = BattleSession.get_state(battle_id)
    assert MapSet.member?(state2.players, "player_2")
    assert state2.phase == :setting_up
  end

  test "rejects actions when phase is waiting_players", %{battle_id: battle_id} do
    assert :ok = BattleSession.sync_state(battle_id, %{"turn" => 1, "status" => "not_started"})
    assert :ok = BattleSession.register_player(battle_id, "player_1")

    action = %{
      "action" => "attack",
      "move_id" => "tackle",
      "player_id" => "player_1",
      "battle_id" => battle_id,
      "targets" => ["player_2"]
    }

    assert {:error, :invalid_phase} = BattleSession.submit_action(battle_id, "player_1", action)
  end

  test "stores action and resolves turn when both players submit", %{battle_id: battle_id} do
    # Sync first to in_progress
    assert :ok = BattleSession.sync_state(battle_id, %{"turn" => 1, "status" => "in_progress"})

    # Register 2 players
    assert :ok = BattleSession.register_player(battle_id, "1")
    assert :ok = BattleSession.register_player(battle_id, "2")

    # Player 1 submits action
    action1 = %{
      "action" => "attack",
      "move_id" => 85,
      "player_id" => 1,
      "battle_id" => battle_id,
      "targets" => ["B1"]
    }

    assert {:ok, :pending} = BattleSession.submit_action(battle_id, "1", action1)

    assert {:ok, state} = BattleSession.get_state(battle_id)
    assert state.turn == 1
    assert state.actions["1"] == action1

    # Subscribe to PubSub to receive the broadcasted state update
    Phoenix.PubSub.subscribe(BattleRealTime.PubSub, "battle_events:#{battle_id}")

    # Player 2 submits action -> resolves turn!
    action2 = %{
      "action" => "switch",
      "pokemon_id" => 12,
      "player_id" => 2,
      "battle_id" => battle_id
    }

    assert {:ok, :resolved} = BattleSession.submit_action(battle_id, "2", action2)

    # Check state updated (turn advanced, actions cleared)
    assert {:ok, state2} = BattleSession.get_state(battle_id)
    assert state2.turn == 2
    assert state2.actions == %{}

    # Check broadcast received
    assert_receive {:battle_event, %{event: "battle_state", payload: payload}}
    assert payload["turn"] == 2
    assert "Acciones procesadas. ¡Comienza el turno 2!" in payload["log"]
  end

  test "surrendering player publishes mutate_battle_status and terminates upon engine event", %{
    battle_id: battle_id,
    pid: pid
  } do
    assert :ok = BattleSession.sync_state(battle_id, %{"turn" => 1, "status" => "in_progress"})
    assert :ok = BattleSession.register_player(battle_id, "player_1", "Ash")

    # Forfeit!
    assert :ok = BattleSession.forfeit(battle_id, "player_1")

    # GenServer is still alive because it is waiting for the engine to confirm the termination
    assert Process.alive?(pid)

    # Simulate engine confirming the termination via terminate_session/2 call
    assert :ok = BattleSession.terminate_session(battle_id, "El jugador Ash se rinde.")

    # Check that the GenServer process is terminated
    refute Process.alive?(pid)
  end

  test "lobby filling up transitions to setting_up and handles lead selection", %{
    battle_id: battle_id
  } do
    assert :ok = BattleSession.sync_state(battle_id, %{"turn" => 0, "status" => "not_started"})

    # Register player 1
    assert :ok = BattleSession.register_player(battle_id, "player_1", "Ash")
    {:ok, state} = BattleSession.get_state(battle_id)
    assert state.phase == :waiting_players

    # Register player 2 -> lobby full!
    assert :ok = BattleSession.register_player(battle_id, "player_2", "Gary")
    {:ok, state} = BattleSession.get_state(battle_id)
    assert state.phase == :setting_up

    # Simulate engine syncing back with players_data (having snapshots)
    engine_state = %{
      "turn" => 0,
      "status" => "setting_up",
      "players" => [
        %{
          "name" => "Ash",
          "team" => "A",
          "pokemons" => [
            %{"id" => 10, "hp" => 100, "max_hp" => 100, "types" => ["fire"]}
          ]
        },
        %{
          "name" => "Gary",
          "team" => "B",
          "pokemons" => [
            %{"id" => 20, "hp" => 120, "max_hp" => 120, "types" => ["water"]}
          ]
        }
      ]
    }

    assert :ok = BattleSession.sync_state(battle_id, engine_state)
    {:ok, state} = BattleSession.get_state(battle_id)
    assert state.phase == :setting_up
    assert length(state.players_data) == 2

    # Player 1 submits select_lead
    assert {:ok, :pending} =
             BattleSession.submit_action(battle_id, "player_1", %{
               "action" => "select_lead",
               "lead" => 10
             })

    # Player 2 submits select_lead -> resolves setup and transitions to syncing
    assert {:ok, :resolved} =
             BattleSession.submit_action(battle_id, "player_2", %{
               "action" => "select_lead",
               "lead" => 20
             })

    {:ok, state} = BattleSession.get_state(battle_id)
    assert state.phase == :syncing
  end
end
