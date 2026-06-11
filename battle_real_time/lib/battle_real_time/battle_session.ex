defmodule BattleRealTime.BattleSession do
  use GenServer, restart: :transient
  require Logger

  @turn_timeout_seconds 120
  @turn_timeout_ms 120_000

  # --- Client API ---

  def start_link(battle_id) do
    GenServer.start_link(__MODULE__, battle_id, name: via_tuple(battle_id))
  end

  def register_player(battle_id, player_id, username \\ "Entrenador") do
    case get_pid(battle_id) do
      nil -> {:error, :not_found}
      pid -> GenServer.call(pid, {:register_player, player_id, username})
    end
  end

  def submit_action(battle_id, player_id, action) do
    case get_pid(battle_id) do
      nil -> {:error, :not_found}
      pid -> GenServer.call(pid, {:submit_action, player_id, action})
    end
  end

  def get_state(battle_id) do
    case get_pid(battle_id) do
      nil -> {:error, :not_found}
      pid -> GenServer.call(pid, :get_state)
    end
  end

  def get_state_payload(battle_id) do
    case get_pid(battle_id) do
      nil -> {:error, :not_found}
      pid -> GenServer.call(pid, :get_state_payload)
    end
  end

  # --- Callbacks ---

  @impl true
  def init(battle_id) do
    Logger.info("Starting BattleSession GenServer for battle: #{battle_id}")

    timer_ref = start_timeout_timer()

    expires_at =
      DateTime.utc_now()
      |> DateTime.add(@turn_timeout_seconds, :second)
      |> DateTime.to_unix(:millisecond)

    state = %{
      battle_id: battle_id,
      turn: 1,
      phase: "waiting_actions",
      players: MapSet.new(),
      player_names: %{},
      actions: %{},
      timer_ref: timer_ref,
      expires_at: expires_at
    }

    # Broadcast initial battle state once started
    broadcast_state(state)

    {:ok, state}
  end

  @impl true
  def handle_call({:register_player, player_id}, from, state) do
    handle_call({:register_player, player_id, "Entrenador"}, from, state)
  end

  @impl true
  def handle_call({:register_player, player_id, username}, _from, state) do
    # Add player to set
    players = MapSet.put(state.players, player_id)
    player_names = Map.put(state.player_names, player_id, username)
    new_state = %{state | players: players, player_names: player_names}

    Logger.info(
      "Player #{player_id} (#{username}) registered in battle #{state.battle_id}. Active players: #{inspect(MapSet.to_list(players))}"
    )

    # Broadcast updated state
    broadcast_state(new_state)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:submit_action, player_id, action}, _from, state) do
    # Ensure player is registered
    players = MapSet.put(state.players, player_id)
    actions = Map.put(state.actions, player_id, action)
    new_state = %{state | players: players, actions: actions}

    Logger.info("Action received from player #{player_id} in battle #{state.battle_id}")

    # Check if we have received actions from all players
    # We require at least 1 player to submit actions to resolve
    if MapSet.size(players) >= 1 and map_size(actions) >= MapSet.size(players) do
      Logger.info(
        "All actions received for turn #{state.turn} in battle #{state.battle_id}. Resolving turn..."
      )

      Logger.info("Actions received: #{inspect(actions)}")

      # Cancel old timer and start a new one
      cancel_timeout_timer(state.timer_ref)
      new_timer_ref = start_timeout_timer()

      new_expires_at =
        DateTime.utc_now()
        |> DateTime.add(@turn_timeout_seconds, :second)
        |> DateTime.to_unix(:millisecond)

      # Resolve turn (for now, just log and advance the turn)
      next_turn = state.turn + 1

      resolved_state = %{
        new_state
        | turn: next_turn,
          actions: %{},
          phase: "waiting_actions",
          timer_ref: new_timer_ref,
          expires_at: new_expires_at
      }

      # Broadcast resolved state to PubSub
      broadcast_state(resolved_state, "Acciones procesadas. ¡Comienza el turno #{next_turn}!")

      {:reply, {:ok, :resolved}, resolved_state}
    else
      {:reply, {:ok, :pending}, new_state}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call(:get_state_payload, _from, state) do
    payload = build_payload(state)
    {:reply, {:ok, payload}, state}
  end

  # --- Helpers ---

  defp via_tuple(battle_id) do
    {:via, Registry, {BattleRealTime.BattleRegistry, battle_id}}
  end

  defp get_pid(battle_id) do
    case Registry.lookup(BattleRealTime.BattleRegistry, battle_id) do
      [{pid, _value}] -> pid
      [] -> nil
    end
  end

  defp build_payload(state, log_message \\ nil) do
    players_list = MapSet.to_list(state.players)

    %{
      "battle_id" => state.battle_id,
      "turn" => state.turn,
      "phase" => state.phase,
      "turn_expires_at" => state.expires_at,
      "log" =>
        if(log_message,
          do: [log_message],
          else: ["Esperando acciones del turno #{state.turn}..."]
        ),
      "player_a_name" =>
        Map.get(state.player_names, Enum.at(players_list, 0) || "", "Entrenador A"),
      "player_b_name" =>
        Map.get(state.player_names, Enum.at(players_list, 1) || "", "Entrenador B"),
      "active_monster_a" => %{
        "id" => "mon_1",
        "name" => "Charizard",
        "hp" => 78,
        "max_hp" => 100,
        "status" => "normal",
        "owner_id" => Enum.at(players_list, 0) || 101
      },
      "active_monster_b" => %{
        "id" => "mon_2",
        "name" => "Gengar",
        "hp" => 92,
        "max_hp" => 100,
        "status" => "normal",
        "owner_id" => Enum.at(players_list, 1) || 102
      }
    }
  end

  defp broadcast_state(state, log_message \\ nil) do
    topic = "battle_events:#{state.battle_id}"
    payload = build_payload(state, log_message)

    # Broadcast to Phoenix PubSub so BattleChannel receives it and pushes to client
    Phoenix.PubSub.broadcast(
      BattleRealTime.PubSub,
      topic,
      {:battle_event, %{event: "battle_state", payload: payload}}
    )
  end

  defp broadcast_timeout(state) do
    topic = "battle_events:#{state.battle_id}"

    payload = %{
      "battle_id" => state.battle_id,
      "reason" => "Se ha excedido el límite de tiempo de espera (2 minutos)."
    }

    Phoenix.PubSub.broadcast(
      BattleRealTime.PubSub,
      topic,
      {:battle_event, %{event: "battle_timeout", payload: payload}}
    )
  end

  defp start_timeout_timer do
    Process.send_after(self(), :turn_timeout, @turn_timeout_ms)
  end

  defp cancel_timeout_timer(nil), do: :ok

  defp cancel_timeout_timer(ref) do
    Process.cancel_timer(ref)
  end

  @impl true
  def handle_info(:turn_timeout, state) do
    Logger.warning("Turn timeout reached for battle #{state.battle_id}. Ending battle session.")
    broadcast_timeout(state)
    {:stop, :normal, state}
  end
end
