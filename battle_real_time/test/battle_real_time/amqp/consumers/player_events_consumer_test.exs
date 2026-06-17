defmodule BattleRealTime.AMQP.Consumers.PlayerEventsConsumerTest do
  use ExUnit.Case, async: true
  alias BattleRealTime.AMQP.Consumers.PlayerEventsConsumer

  describe "process_message/2" do
    test "with valid info event, validates and broadcasts to the player's PubSub topic" do
      player_name = "Mancha"
      topic = "player:#{player_name}"

      # Subscribe test process to the player topic
      Phoenix.PubSub.subscribe(BattleRealTime.PubSub, topic)

      data = %{
        "player" => %{
          "id" => 101,
          "name" => player_name,
          "team" => "A",
          "battle_history" => %{
            "victories" => 3,
            "defeats" => 1
          }
        }
      }

      # Run processing
      assert :ok = PlayerEventsConsumer.process_message("info", data)

      # Assert PubSub broadcast occurred and payload has atom keys/nested structure
      assert_receive {:player_event, %{event: "info", payload: payload}}
      assert payload.player.id == 101
      assert payload.player.name == player_name
      assert payload.player.battle_history.victories == 3
    end

    test "with invalid info event, does not broadcast and logs validation error" do
      player_name = "Mancha"
      topic = "player:#{player_name}"

      # Subscribe test process to the player topic
      Phoenix.PubSub.subscribe(BattleRealTime.PubSub, topic)

      # Missing required field "battle_history"
      invalid_data = %{
        "player" => %{
          "id" => 101,
          "name" => player_name
        }
      }

      # Run processing
      PlayerEventsConsumer.process_message("info", invalid_data)

      # Assert no message was broadcast to this topic
      refute_receive {:player_event, _}
    end

    test "with non-info event, does not crash and warns" do
      Phoenix.PubSub.subscribe(BattleRealTime.PubSub, "player:some_player")

      # Run processing on arbitrary event
      PlayerEventsConsumer.process_message("other_event", %{"some" => "data"})

      refute_receive {:player_event, _}
    end

    test "with valid battles_info event, validates and broadcasts to the player's PubSub topic" do
      player_id = 101
      topic = "player:#{player_id}"

      # Subscribe test process to the player topic
      Phoenix.PubSub.subscribe(BattleRealTime.PubSub, topic)

      data = %{
        "player_id" => player_id,
        "battles" => [
          %{
            "id" => "battle-uuid-1",
            "players" => [
              %{"name" => "Mancha", "team" => "A"},
              %{"name" => "Enemy", "team" => "B"}
            ]
          }
        ]
      }

      # Run processing
      assert :ok = PlayerEventsConsumer.process_message("battles_info", data)

      # Assert PubSub broadcast occurred and payload has atom keys/nested structure
      assert_receive {:player_event, %{event: "battles_info", payload: payload}}
      assert payload.player_id == player_id
      assert length(payload.battles) == 1
      [battle] = payload.battles
      assert battle.id == "battle-uuid-1"
      assert length(battle.players) == 2
      [p1, p2] = battle.players
      assert p1.name == "Mancha"
      assert p1.team == "A"
      assert p2.name == "Enemy"
      assert p2.team == "B"
    end
  end
end
