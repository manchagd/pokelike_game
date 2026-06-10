defmodule BattleRealTimeWeb.BattleChatChannelTest do
  use BattleRealTimeWeb.ChannelCase
  alias BattleRealTimeWeb.UserSocket
  alias BattleRealTimeWeb.BattleChatChannel

  setup do
    {:ok, socket} = connect(UserSocket, %{})
    %{socket: socket}
  end

  test "joins with battle_chat topic and sets custom assigns", %{socket: socket} do
    {:ok, reply, join_socket} =
      subscribe_and_join(socket, BattleChatChannel, "battle_chat:battle_123", %{
        "username" => "Ash Ketchum",
        "player_id" => "player_abc"
      })

    assert reply.battle_id == "battle_123"
    assert reply.username == "Ash Ketchum"
    assert reply.player_id == "player_abc"
    assert join_socket.assigns.battle_id == "battle_123"
    assert join_socket.assigns.username == "Ash Ketchum"
    assert join_socket.assigns.player_id == "player_abc"
  end

  test "joins with default username", %{socket: socket} do
    {:ok, reply, join_socket} =
      subscribe_and_join(socket, BattleChatChannel, "battle_chat:battle_123", %{})

    assert reply.username == "Anonymous"
    assert is_nil(reply.player_id)
    assert join_socket.assigns.username == "Anonymous"
    assert is_nil(join_socket.assigns.player_id)
  end

  test "broadcasts message and returns reply on send_message", %{socket: socket} do
    {:ok, _, join_socket} =
      subscribe_and_join(socket, BattleChatChannel, "battle_chat:battle_456", %{
        "username" => "Gary Oak",
        "player_id" => "player_xyz"
      })

    ref = push(join_socket, "send_message", %{"body" => "Smell ya later!"})

    assert_reply ref, :ok, %{
      "body" => "Smell ya later!",
      "username" => "Gary Oak",
      "player_id" => "player_xyz",
      "timestamp" => timestamp
    }

    assert is_binary(timestamp)

    assert_broadcast "new_message", %{
      "body" => "Smell ya later!",
      "username" => "Gary Oak",
      "player_id" => "player_xyz",
      "timestamp" => ^timestamp
    }
  end

  test "returns error reply on empty send_message", %{socket: socket} do
    {:ok, _, join_socket} =
      subscribe_and_join(socket, BattleChatChannel, "battle_chat:battle_456", %{})

    ref = push(join_socket, "send_message", %{"body" => "   "})
    assert_reply ref, :error, %{reason: "message body cannot be empty"}
  end
end
