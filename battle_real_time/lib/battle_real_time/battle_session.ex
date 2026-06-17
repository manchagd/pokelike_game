defmodule BattleRealTime.BattleSession do
  use GenServer, restart: :transient
  require Logger

  @turn_timeout_seconds 300

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

  def forfeit(battle_id, player_id) do
    case get_pid(battle_id) do
      nil -> {:error, :not_found}
      pid -> GenServer.call(pid, {:forfeit, player_id})
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

  def sync_state(battle_id, engine_state) do
    case get_pid(battle_id) do
      nil -> {:error, :not_found}
      pid -> GenServer.call(pid, {:sync_state, engine_state})
    end
  end

  def terminate_session(battle_id, reason) do
    case get_pid(battle_id) do
      nil -> {:error, :not_found}
      pid -> GenServer.call(pid, {:terminate_session, reason})
    end
  end

  # --- Callbacks ---

  @impl true
  def init(battle_id) do
    Logger.info("Starting BattleSession GenServer for battle: #{battle_id}")

    state = %{
      battle_id: battle_id,
      battle_format: "1v1",
      turn: 0,
      phase: :syncing,
      players: MapSet.new(),
      player_names: %{},
      players_data: [],
      actions: %{},
      timer_ref: nil,
      expires_at: nil,
      logs: ["Sincronizando Batalla..."]
    }

    # Publish battle_sync event instead of broadcasting
    publish_battle_sync(battle_id)

    {:ok, state}
  end

  @impl true
  def handle_call({:register_player, player_id}, from, state) do
    handle_call({:register_player, player_id, "Entrenador"}, from, state)
  end

  def handle_call({:register_player, player_id, username}, _from, state) do
    # Add player to set
    players = MapSet.put(state.players, player_id)
    player_names = Map.put(state.player_names, player_id, username)

    expected = expected_players_count(state.battle_format)
    current_count = MapSet.size(players)

    {new_phase, new_timer_ref, new_expires_at, log_message, should_broadcast} =
      if waiting_players?(state) and current_count >= expected do
        cancel_timeout_timer(state.timer_ref)

        # Publish mutation to engine
        publish_mutate_battle_status(state.battle_id, "setting_up")

        {:setting_up, nil, nil, "Ambos entrenadores conectados. Preparando selección de líder...",
         false}
      else
        {state.phase, state.timer_ref, state.expires_at, nil, true}
      end

    log_message = log_message || "El entrenador #{username} se ha unido al lobby."

    new_state =
      %{
        state
        | players: players,
          player_names: player_names,
          phase: new_phase,
          timer_ref: new_timer_ref,
          expires_at: new_expires_at
      }
      |> add_log(log_message)

    Logger.info(
      "Player #{player_id} (#{username}) registered in battle #{state.battle_id}. Active players: #{inspect(MapSet.to_list(players))}. Phase: #{new_phase}"
    )

    if should_broadcast do
      broadcast_state(new_state)
    end

    {:reply, :ok, new_state}
  end

  def handle_call(
        {:submit_action, player_id, %{"action" => "select_lead", "lead" => lead}},
        _from,
        state
      ) do
    if state.phase != :setting_up do
      {:reply, {:error, :invalid_phase}, state}
    else
      actions = Map.put(state.actions, player_id, %{"player_id" => player_id, "lead" => lead})
      new_state = %{state | actions: actions}

      expected = expected_players_count(state.battle_format)
      current_actions_count = map_size(actions)

      Logger.info("Lead choice received from player #{player_id} in battle #{state.battle_id}")

      if current_actions_count >= expected do
        publish_select_leads(state.battle_id, Map.values(actions))
        resolved_state = %{new_state | actions: %{}, phase: :syncing}
        {:reply, {:ok, :resolved}, resolved_state}
      else
        {:reply, {:ok, :pending}, new_state}
      end
    end
  end

  def handle_call({:submit_action, player_id, action}, _from, state) do
    if not waiting_actions?(state) do
      {:reply, {:error, :invalid_phase}, state}
    else
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

        # Publish consolidated turn_actions to RabbitMQ
        publish_turn_actions(state.battle_id, state.turn, actions)

        # Resolve turn (for now, just log and advance the turn)
        next_turn = state.turn + 1

        resolved_state =
          %{
            new_state
            | turn: next_turn,
              actions: %{},
              phase: :waiting_actions,
              timer_ref: new_timer_ref,
              expires_at: new_expires_at()
          }
          |> add_log("Acciones procesadas. ¡Comienza el turno #{next_turn}!")

        # Broadcast resolved state to PubSub
        broadcast_state(resolved_state)

        {:reply, {:ok, :resolved}, resolved_state}
      else
        {:reply, {:ok, :pending}, new_state}
      end
    end
  end

  def handle_call({:forfeit, player_id}, _from, state) do
    username = Map.get(state.player_names, player_id, "Entrenador")

    publish_mutate_battle_status(state.battle_id, "finished", "El jugador #{username} se rinde.")

    Logger.info(
      "Forfeit requested by player #{player_id} (#{username}) in battle #{state.battle_id}. Published mutate_battle_status."
    )

    {:reply, :ok, state}
  end

  def handle_call({:sync_state, engine_state}, _from, state) do
    new_turn = Map.get(engine_state, "turn", state.turn)
    new_phase_str = Map.get(engine_state, "status", Atom.to_string(state.phase))
    new_players_data = Map.get(engine_state, "players", [])

    new_phase =
      case new_phase_str do
        "not_started" ->
          :waiting_players

        "in_progress" ->
          :waiting_actions

        "finished" ->
          :finished

        other ->
          try do
            String.to_existing_atom(other)
          rescue
            _ -> String.to_atom(other)
          end
      end

    {new_timer_ref, new_expires_at} =
      if new_phase == :waiting_actions do
        cancel_timeout_timer(state.timer_ref)
        {start_timeout_timer(), new_expires_at()}
      else
        if new_phase in [:finished, :syncing, :setting_up] do
          cancel_timeout_timer(state.timer_ref)
          {nil, nil}
        else
          {state.timer_ref, state.expires_at}
        end
      end

    log_msg = "Estado sincronizado con el Engine. Turno #{new_turn}."

    new_state =
      %{
        state
        | turn: new_turn,
          phase: new_phase,
          timer_ref: new_timer_ref,
          expires_at: new_expires_at,
          players_data: new_players_data
      }
      |> add_log(log_msg)

    broadcast_state(new_state)

    {:reply, :ok, new_state}
  end

  def handle_call({:terminate_session, reason}, _from, state) do
    Logger.info("Terminating battle session #{state.battle_id} with reason: #{reason}")

    cancel_timeout_timer(state.timer_ref)

    new_state = %{state | phase: :finished, timer_ref: nil, expires_at: nil}

    {:stop, :normal, :ok, new_state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

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

  defp publish_turn_actions(battle_id, turn, actions) do
    payload = %{
      "battle_id" => battle_id,
      "turn" => turn,
      "actions" => Map.values(actions)
    }

    BattleRealTime.AMQP.Publishers.BattleActionsPublisher.publish("turn_actions", payload)
  end

  defp publish_select_leads(battle_id, players_leads) do
    payload = %{
      "battle_id" => battle_id,
      "players" => players_leads
    }

    BattleRealTime.AMQP.Publishers.BattleActionsPublisher.publish("select_leads", payload)
  end

  defp build_payload(state) do
    players_list = MapSet.to_list(state.players)
    expected = expected_players_count(state.battle_format)
    current_count = MapSet.size(state.players)

    payload_logs =
      if state.phase in [:waiting_players, :waiting_actions] do
        state.logs ++ [default_log_message(state)]
      else
        state.logs
      end

    masked_players =
      if state.phase == :setting_up do
        Enum.map(state.players_data, fn player ->
          %{
            "name" => player["name"],
            "team" => player["team"],
            "pokemon_count" => length(player["pokemons"] || [])
          }
        end)
      else
        state.players_data
      end

    %{
      "battle_id" => state.battle_id,
      "battle_format" => state.battle_format,
      "turn" => state.turn,
      "phase" => Atom.to_string(state.phase),
      "turn_expires_at" => state.expires_at,
      "expected_players" => expected,
      "connected_players" => current_count,
      "log" => payload_logs,
      "player_a_name" =>
        Map.get(state.player_names, Enum.at(players_list, 0) || "", "Entrenador A"),
      "player_b_name" =>
        Map.get(state.player_names, Enum.at(players_list, 1) || "", "Entrenador B"),
      "players" => masked_players,
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

  defp broadcast_state(state) do
    topic = "battle_events:#{state.battle_id}"
    payload = build_payload(state)

    # Broadcast to Phoenix PubSub so BattleChannel receives it and pushes to client
    Phoenix.PubSub.broadcast(
      BattleRealTime.PubSub,
      topic,
      {:battle_event, %{event: "battle_state", payload: payload}}
    )

    if state.phase == :setting_up do
      broadcast_private_setup_pokemons(state)
    end
  end

  defp broadcast_private_setup_pokemons(state) do
    Enum.each(state.players_data, fn player_data ->
      player_id = find_player_id_by_name(state, player_data["name"])

      if player_id do
        private_topic = "battle_events:#{state.battle_id}:#{player_id}"

        Phoenix.PubSub.broadcast(
          BattleRealTime.PubSub,
          private_topic,
          {:battle_event,
           %{
             event: "setup_pokemons",
             payload: %{
               "battle_id" => state.battle_id,
               "pokemons" => player_data["pokemons"]
             }
           }}
        )
      end
    end)
  end

  defp find_player_id_by_name(state, name) do
    Enum.find_value(state.player_names, nil, fn {player_id, username} ->
      if username == name, do: player_id, else: nil
    end)
  end

  defp add_log(state, nil), do: state

  defp add_log(state, message) do
    if List.last(state.logs) == message do
      state
    else
      %{state | logs: state.logs ++ [message]}
    end
  end

  def broadcast_battle_ended(battle_id, reason) do
    topic = "battle_events:#{battle_id}"

    payload = %{
      "battle_id" => battle_id,
      "reason" => reason
    }

    Phoenix.PubSub.broadcast(
      BattleRealTime.PubSub,
      topic,
      {:battle_event, %{event: "battle_ended", payload: payload}}
    )
  end

  defp publish_mutate_battle_status(battle_id, status, reason \\ nil) do
    payload =
      %{
        "battle_id" => battle_id,
        "status" => status,
        "reason" => reason
      }
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    BattleRealTime.AMQP.Publishers.BattleActionsPublisher.publish("mutate_battle_status", payload)
  end

  defp start_timeout_timer do
    Process.send_after(self(), :turn_timeout, @turn_timeout_seconds * 1000)
  end

  defp new_expires_at do
    DateTime.utc_now()
    |> DateTime.add(@turn_timeout_seconds, :second)
    |> DateTime.to_unix(:millisecond)
  end

  defp cancel_timeout_timer(nil), do: :ok

  defp cancel_timeout_timer(ref) do
    Process.cancel_timer(ref)
  end

  defp expected_players_count("1v1"), do: 2
  defp expected_players_count("2v2"), do: 4
  defp expected_players_count(_other), do: 2

  def syncing?(state), do: state.phase == :syncing
  def setting_up?(state), do: state.phase == :setting_up
  def waiting_players?(state), do: state.phase == :waiting_players
  def waiting_actions?(state), do: state.phase == :waiting_actions
  def finished?(state), do: state.phase == :finished

  defp publish_battle_sync(battle_id) do
    payload = %{
      "battle_id" => battle_id
    }

    BattleRealTime.AMQP.Publishers.BattleActionsPublisher.publish("battle_sync", payload)
  end

  defp default_log_message(%{phase: :waiting_players} = state) do
    expected = expected_players_count(state.battle_format)
    current = MapSet.size(state.players)
    "Esperando jugadores (#{current}/#{expected})..."
  end

  defp default_log_message(state) do
    "Esperando acciones del turno #{state.turn}..."
  end

  @impl true
  def handle_info(:turn_timeout, state) do
    Logger.warning(
      "Turn timeout reached for battle #{state.battle_id}. Publishing mutate_battle_status."
    )

    publish_mutate_battle_status(
      state.battle_id,
      "finished",
      "Se ha excedido el límite de tiempo de espera (5 minutos)."
    )

    {:noreply, state}
  end
end
