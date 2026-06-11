defmodule BattleRealTimeWeb.PlayerChannel do
  use Phoenix.Channel
  require Logger

  @impl true
  def join("player:" <> identifier, _params, socket) do
    socket = assign(socket, :identifier, identifier)

    # Subscribe this channel process to PubSub events for this player (name or ID)
    Phoenix.PubSub.subscribe(BattleRealTime.PubSub, "player:#{identifier}")

    Logger.info("Client joined player:#{identifier}")
    {:ok, %{identifier: identifier}, socket}
  end

  # Client requests registration
  @impl true
  def handle_in("register", _payload, socket) do
    name = socket.assigns.identifier
    Logger.info("Registration request received for player: #{name}")
    # Publish to the player_actions queue via PlayerActionsPublisher
    BattleRealTime.AMQP.Publishers.PlayerActionsPublisher.publish("register", %{"name" => name})
    {:noreply, socket}
  end

  # Receive player events from PubSub and push them to the client
  @impl true
  def handle_info({:player_event, %{event: event, payload: payload}}, socket) do
    push(socket, "player_event", %{event: event, payload: payload})
    {:noreply, socket}
  end

  @impl true
  def handle_info(msg, socket) do
    Logger.warning("Unhandled handle_info message: #{inspect(msg)}")
    {:noreply, socket}
  end
end
