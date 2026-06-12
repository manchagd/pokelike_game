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

    case BattleRealTime.Players.RegisterPlayer.call(name) do
      :ok -> {:noreply, socket}
      {:error, _reason} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_in("create_battle", _payload, socket) do
    player_id = socket.assigns.identifier
    Logger.info("Create battle request received for player: #{player_id}")

    case BattleRealTime.Players.CreateBattle.call(player_id) do
      {:ok, _payload} -> {:noreply, socket}
      {:error, _reason} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_in("join_battle", payload, socket) do
    player_id = socket.assigns.identifier
    battle_id = Map.get(payload, "battle_id")
    Logger.info("Join battle request received for player: #{player_id}, battle: #{battle_id}")

    case BattleRealTime.Players.RequestJoinBattle.call(player_id, battle_id) do
      {:ok, _payload} -> {:noreply, socket}
      {:error, _reason} -> {:noreply, socket}
    end
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
