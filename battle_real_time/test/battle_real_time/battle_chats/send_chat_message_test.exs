defmodule BattleRealTime.BattleChats.SendChatMessageTest do
  use ExUnit.Case, async: true
  alias BattleRealTime.BattleChats.SendChatMessage

  test "returns {:ok, message_payload} for valid non-empty body" do
    assert {:ok, payload} = SendChatMessage.call("player_1", "Ash", "Go Pikachu!")
    assert payload["body"] == "Go Pikachu!"
    assert payload["username"] == "Ash"
    assert payload["player_id"] == "player_1"
    assert is_binary(payload["timestamp"])
  end

  test "returns {:error, reason} for empty body" do
    assert {:error, :invalid_body} = SendChatMessage.call("player_1", "Ash", "")
    assert {:error, :invalid_body} = SendChatMessage.call("player_1", "Ash", "   ")
    assert {:error, :invalid_body} = SendChatMessage.call("player_1", "Ash", nil)
  end
end
