defmodule BattleRealTimeWeb.BattleChannel do
  use Phoenix.Channel

  alias BattleRealTime.BattleSession
  require Logger

  @impl true
  def join("battle:" <> battle_id, params, socket) do
    socket = assign(socket, :battle_id, battle_id)
    player_id = Map.get(params, "player_id")
    username = Map.get(params, "username") || "Entrenador"
    socket = assign(socket, :player_id, player_id)

    # Ensure BattleSession GenServer is running
    case Registry.lookup(BattleRealTime.BattleRegistry, battle_id) do
      [] ->
        Logger.info("Starting new BattleSession for battle:#{battle_id}")

        DynamicSupervisor.start_child(
          BattleRealTime.BattleSupervisor,
          {BattleSession, battle_id}
        )

      _ ->
        Logger.info("BattleSession for battle:#{battle_id} already exists")
        :ok
    end

    # Subscribe this channel process to PubSub events for this specific battle
    Phoenix.PubSub.subscribe(BattleRealTime.PubSub, "battle_events:#{battle_id}")

    # Register player in the battle session
    if player_id != nil and player_id != "" do
      BattleSession.register_player(battle_id, player_id, username)
    end

    Logger.info("Client joined battle:#{battle_id} as player:#{player_id} (#{username})")
    send(self(), :after_join)
    {:ok, %{battle_id: battle_id}, socket}
  end

  # Client sends an action -> forward to BattleSession and publish to RabbitMQ
  @impl true
  def handle_in("action", %{"action" => action} = payload, socket) do
    battle_id = socket.assigns.battle_id
    player_id = socket.assigns.player_id
    enriched = payload |> Map.put("battle_id", battle_id) |> Map.put("player_id", player_id)

    Logger.info("Received action '#{action}' from player '#{player_id}' for battle:#{battle_id}")

    # 1. Forward action to BattleSession GenServer
    if player_id != nil and player_id != "" do
      BattleSession.submit_action(battle_id, player_id, enriched)
    end

    # 2. Publish action to RabbitMQ
    BattleRealTime.AMQP.Publishers.BattleActionsPublisher.publish(action, enriched)

    {:noreply, socket}
  end

  # Catch-all for unknown incoming events
  def handle_in(event, _payload, socket) do
    Logger.warning("Unknown event '#{event}'")
    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    battle_id = socket.assigns.battle_id

    case BattleSession.get_state_payload(battle_id) do
      {:ok, payload} ->
        push(socket, "battle_event", %{event: "battle_state", payload: payload})

      _ ->
        :ok
    end

    {:noreply, socket}
  end

  # AMQP Consumer or BattleSession broadcasts here -> forward to connected client
  @impl true
  def handle_info({:battle_event, %{event: event, payload: payload}}, socket) do
    push(socket, "battle_event", %{event: event, payload: payload})
    {:noreply, socket}
  end
end
