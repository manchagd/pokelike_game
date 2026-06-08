defmodule BattleRealTimeWeb.BattleChannel do
  use Phoenix.Channel

  require Logger

  @impl true
  def join("battle:" <> battle_id, _params, socket) do
    socket = assign(socket, :battle_id, battle_id)

    # Subscribe this channel process to PubSub events for this specific battle
    Phoenix.PubSub.subscribe(BattleRealTime.PubSub, "battle_events:#{battle_id}")

    Logger.info("[BattleChannel] Client joined battle:#{battle_id}")
    {:ok, %{battle_id: battle_id}, socket}
  end

  # Client sends an action -> publish to RabbitMQ battle_actions queue
  @impl true
  def handle_in("action", %{"action" => action} = payload, socket) do
    battle_id = socket.assigns.battle_id
    enriched = Map.put(payload, "battle_id", battle_id)

    Logger.info("[BattleChannel] Received action '#{action}' for battle:#{battle_id}")
    BattleRealTime.AMQP.BattleActionsPublisher.publish(action, enriched)

    {:noreply, socket}
  end

  # Catch-all for unknown incoming events
  def handle_in(event, _payload, socket) do
    Logger.warning("[BattleChannel] Unknown event '#{event}'")
    {:noreply, socket}
  end

  # AMQP Consumer broadcasts here -> forward to connected client
  @impl true
  def handle_info({:battle_event, %{event: event, payload: payload}}, socket) do
    push(socket, "battle_event", %{event: event, payload: payload})
    {:noreply, socket}
  end
end
