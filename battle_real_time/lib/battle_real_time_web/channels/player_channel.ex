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
      :ok ->
        {:noreply, socket}

      {:error, reason} ->
        Logger.error("Failed to register player '#{name}': #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("create_battle", payload, socket) do
    player_id = socket.assigns.identifier
    team_id = Map.get(payload, "team_id")

    Logger.info(
      "Create battle request received for player: #{player_id}, team_id: #{inspect(team_id)}"
    )

    case BattleRealTime.Players.CreateBattle.call(player_id, team_id) do
      {:ok, _payload} ->
        {:noreply, socket}

      {:error, reason} ->
        Logger.error(
          "Failed to create battle for player '#{player_id}' with team '#{inspect(team_id)}': #{inspect(reason)}"
        )

        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("join_battle", payload, socket) do
    player_id = socket.assigns.identifier
    battle_id = Map.get(payload, "battle_id")
    team_id = Map.get(payload, "team_id")

    Logger.info(
      "Join battle request received for player: #{player_id}, battle: #{battle_id}, team_id: #{inspect(team_id)}"
    )

    case BattleRealTime.Players.JoinBattle.call(player_id, battle_id, team_id) do
      {:ok, _payload} ->
        {:noreply, socket}

      {:error, reason} ->
        Logger.error(
          "Failed to join battle '#{battle_id}' for player '#{player_id}' with team '#{inspect(team_id)}': #{inspect(reason)}"
        )

        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("get_pokemon_templates", _payload, socket) do
    player_id = socket.assigns.identifier
    Logger.info("Get pokemon templates request received for player: #{player_id}")

    case BattleRealTime.Players.GetPokemonTemplates.call(player_id) do
      {:ok, _payload} ->
        {:noreply, socket}

      {:error, reason} ->
        Logger.error(
          "Failed to get pokemon templates for player '#{player_id}': #{inspect(reason)}"
        )

        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("get_pokemon_template_moves", payload, socket) do
    player_id = socket.assigns.identifier
    pokemon_template_id = Map.get(payload, "pokemon_template_id")

    Logger.info(
      "Get pokemon template moves request received for player: #{player_id}, template: #{pokemon_template_id}"
    )

    case BattleRealTime.Players.GetPokemonTemplateMoves.call(player_id, pokemon_template_id) do
      {:ok, _payload} ->
        {:noreply, socket}

      {:error, reason} ->
        Logger.error(
          "Failed to get pokemon template moves for player '#{player_id}', template '#{pokemon_template_id}': #{inspect(reason)}"
        )

        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("mutate_team", payload, socket) do
    player_id = socket.assigns.identifier
    name = Map.get(payload, "name")
    pokemons = Map.get(payload, "pokemons")
    team_id = Map.get(payload, "team_id")

    Logger.info(
      "Mutate team request received for player: #{player_id}, name: #{name}, team_id: #{team_id}"
    )

    case BattleRealTime.Players.MutateTeam.call(player_id, name, pokemons, team_id) do
      {:ok, _payload} ->
        {:noreply, socket}

      {:error, reason} ->
        Logger.error(
          "Failed to mutate team for player '#{player_id}', team_id '#{inspect(team_id)}': #{inspect(reason)}"
        )

        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("get_team_details", payload, socket) do
    player_id = socket.assigns.identifier
    team_id = Map.get(payload, "team_id")
    Logger.info("Get team details request received for player: #{player_id}, team_id: #{team_id}")

    case BattleRealTime.Players.GetTeamDetails.call(player_id, team_id) do
      {:ok, _payload} ->
        {:noreply, socket}

      {:error, reason} ->
        Logger.error(
          "Failed to get team details for player '#{player_id}', team_id '#{team_id}': #{inspect(reason)}"
        )

        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("delete_team", payload, socket) do
    player_id = socket.assigns.identifier
    team_id = Map.get(payload, "team_id")
    Logger.info("Delete team request received for player: #{player_id}, team_id: #{team_id}")

    case BattleRealTime.Players.DeleteTeam.call(player_id, team_id) do
      {:ok, _payload} ->
        {:noreply, socket}

      {:error, reason} ->
        Logger.error(
          "Failed to delete team for player '#{player_id}', team_id '#{team_id}': #{inspect(reason)}"
        )

        {:noreply, socket}
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
