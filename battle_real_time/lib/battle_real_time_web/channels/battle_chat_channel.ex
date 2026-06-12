defmodule BattleRealTimeWeb.BattleChatChannel do
  use BattleRealTimeWeb, :channel
  require Logger

  @impl true
  def join("battle_chat:" <> battle_id, params, socket) do
    username = Map.get(params, "username", "Anonymous")
    player_id = Map.get(params, "player_id")

    socket =
      socket
      |> assign(:battle_id, battle_id)
      |> assign(:username, username)
      |> assign(:player_id, player_id)

    Logger.info("Player '#{username}' joined battle_chat:#{battle_id}")

    {:ok, %{battle_id: battle_id, username: username, player_id: player_id}, socket}
  end

  # Client sends a message -> broadcast to all users in the same room
  @impl true
  def handle_in("send_message", %{"body" => body}, socket) do
    player_id = socket.assigns.player_id
    username = socket.assigns.username

    case BattleRealTime.BattleChats.SendChatMessage.call(player_id, username, body) do
      {:ok, message_payload} ->
        # Broadcast to all connections listening to this battle_chat:<battle_id>
        broadcast!(socket, "new_message", message_payload)
        {:reply, {:ok, message_payload}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  # Catch-all for unknown incoming events
  @impl true
  def handle_in(event, _payload, socket) do
    Logger.warning("Unknown event '#{event}'")
    {:noreply, socket}
  end
end
