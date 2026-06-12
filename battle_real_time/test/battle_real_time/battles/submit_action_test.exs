defmodule BattleRealTime.Battles.SubmitActionTest do
  use ExUnit.Case, async: true
  alias BattleRealTime.Battles.SubmitAction
  alias BattleRealTime.BattleSession

  setup do
    battle_id = "test_battle_#{System.unique_integer([:positive])}"

    {:ok, _pid} =
      DynamicSupervisor.start_child(
        BattleRealTime.BattleSupervisor,
        {BattleSession, battle_id}
      )

    # Register players to transition phase to :waiting_actions
    :ok = BattleSession.register_player(battle_id, "player_1")
    :ok = BattleSession.register_player(battle_id, "player_2")

    %{battle_id: battle_id}
  end

  test "submits a valid action", %{battle_id: battle_id} do
    payload = %{
      "action" => "attack",
      "move_id" => "tackle",
      "targets" => ["player_2"]
    }

    assert {:ok, enriched} = SubmitAction.call(battle_id, "player_1", payload)
    assert enriched["battle_id"] == battle_id
    assert enriched["player_id"] == "player_1"

    # Verify action registered in session
    assert {:ok, state} = BattleSession.get_state(battle_id)
    assert state.actions["player_1"] == enriched
  end

  test "returns error with empty player_id", %{battle_id: battle_id} do
    payload = %{"action" => "attack"}
    assert {:error, :invalid_player} = SubmitAction.call(battle_id, "", payload)
    assert {:error, :invalid_player} = SubmitAction.call(battle_id, nil, payload)
  end

  test "returns {:error, :battle_not_found} if battle does not exist" do
    payload = %{"action" => "attack"}

    assert {:error, :battle_not_found} =
             SubmitAction.call("non_existent_battle", "player_1", payload)
  end
end
