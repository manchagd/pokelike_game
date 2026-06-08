defmodule BattleRealTimeWeb.PlayerChannel do
  use Phoenix.Channel
  require Logger

  @impl true
  def join("player:" <> identifier, _params, socket) do
    socket = assign(socket, :identifier, identifier)

    # Subscribe this channel process to PubSub events for this player (name or ID)
    Phoenix.PubSub.subscribe(BattleRealTime.PubSub, "player:#{identifier}")

    Logger.info("[PlayerChannel] Client joined player:#{identifier}")
    {:ok, %{identifier: identifier}, socket}
  end

  # Receive player events from PubSub and push them to the client
  @impl true
  def handle_info({:player_event, %{event: event, payload: payload}}, socket) do
    push(socket, "player_event", %{event: event, payload: payload})
    {:noreply, socket}
  end

  @impl true
  def handle_info(msg, socket) do
    Logger.warning("[PlayerChannel] Unhandled handle_info message: #{inspect(msg)}")
    {:noreply, socket}
  end
end
