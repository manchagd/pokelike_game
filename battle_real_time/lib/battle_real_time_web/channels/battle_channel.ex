defmodule BattleRealTimeWeb.BattleChannel do
  use Phoenix.Channel

  alias BattleRealTime.BattleSession
  require Logger

  @impl true
  def join("battle:" <> topic_suffix, params, socket) do
    case String.split(topic_suffix, ":", parts: 2) do
      [battle_id, player_id] ->
        join_topic(battle_id, player_id, params, socket)

      [battle_id] ->
        join_topic(battle_id, params, socket)
    end
  end

  defp join_topic(battle_id, player_id, _params, socket)
       when is_binary(player_id) and player_id != "" do
    socket =
      socket
      |> assign(:battle_id, battle_id)
      |> assign(:player_id, player_id)

    Phoenix.PubSub.subscribe(BattleRealTime.PubSub, "battle_events:#{battle_id}:#{player_id}")

    Logger.info(
      "Client joined private battle channel for battle:#{battle_id} and player:#{player_id}"
    )

    {:ok, %{battle_id: battle_id, player_id: player_id}, socket}
  end

  defp join_topic(battle_id, params, socket) do
    player_id = Map.get(params, "player_id")
    username = Map.get(params, "username", "Entrenador")

    socket =
      socket
      |> assign(:battle_id, battle_id)
      |> assign(:player_id, player_id)

    case BattleRealTime.Battles.ConnectToBattle.call(battle_id, player_id, username) do
      {:ok, _} ->
        Phoenix.PubSub.subscribe(BattleRealTime.PubSub, "battle_events:#{battle_id}")

        Logger.info(
          "Client joined public battle:#{battle_id} as player:#{player_id} (#{username})"
        )

        send(self(), :after_join)
        {:ok, %{battle_id: battle_id}, socket}

      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end

  # Client sends an action -> forward to BattleSession and publish to RabbitMQ
  @impl true
  def handle_in("action", %{"action" => "forfeit"}, socket) do
    battle_id = socket.assigns.battle_id
    player_id = socket.assigns.player_id

    Logger.info("Forfeit action received from player '#{player_id}' for battle:#{battle_id}")

    case BattleRealTime.Battles.Forfeit.call(battle_id, player_id) do
      :ok ->
        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("action", %{"action" => action} = payload, socket) do
    battle_id = socket.assigns.battle_id
    player_id = socket.assigns.player_id

    Logger.info("Received action '#{action}' from player '#{player_id}' for battle:#{battle_id}")

    case BattleRealTime.Battles.SubmitAction.call(battle_id, player_id, payload) do
      {:ok, _enriched} ->
        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("select_lead", %{"lead" => lead}, socket) do
    battle_id = socket.assigns.battle_id
    player_id = socket.assigns.player_id
    payload = %{"action" => "select_lead", "lead" => lead}

    case BattleRealTime.Battles.SubmitAction.call(battle_id, player_id, payload) do
      {:ok, _} -> {:noreply, socket}
      {:error, _} -> {:noreply, socket}
    end
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
