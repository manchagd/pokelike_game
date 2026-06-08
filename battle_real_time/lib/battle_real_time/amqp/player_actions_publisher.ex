defmodule BattleRealTime.AMQP.PlayerActionsPublisher do
  @moduledoc """
  Publishes player action messages to the `player_actions` RabbitMQ queue.
  """

  use GenServer
  require Logger

  @queue "player_actions"
  @reconnect_interval 5_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Publishes an action to the player_actions queue.
  """
  def publish(action, payload \\ %{}) do
    GenServer.cast(__MODULE__, {:publish, action, payload})
  end

  # --- Callbacks ---

  @impl true
  def init(_) do
    send(self(), :connect)
    {:ok, nil}
  end

  @impl true
  def handle_info(:connect, _state) do
    case BattleRealTime.AMQP.Connection.get() do
      {:ok, conn} ->
        case AMQP.Channel.open(conn) do
          {:ok, chan} ->
            AMQP.Queue.declare(chan, @queue, durable: true)
            Logger.info("[AMQP.PlayerActionsPublisher] Ready to publish to queue '#{@queue}'")
            {:noreply, chan}

          {:error, reason} ->
            Logger.error("[AMQP.PlayerActionsPublisher] Failed to open channel: #{inspect(reason)}")
            Process.send_after(self(), :connect, @reconnect_interval)
            {:noreply, nil}
        end

      {:error, _} ->
        Process.send_after(self(), :connect, @reconnect_interval)
        {:noreply, nil}
    end
  end

  @impl true
  def handle_cast({:publish, _action, _payload}, nil) do
    Logger.error("[AMQP.PlayerActionsPublisher] Not connected to RabbitMQ — dropping message")
    {:noreply, nil}
  end

  def handle_cast({:publish, action, payload}, chan) do
    message =
      Jason.encode!(%{
        event: action,
        payload:
          Map.merge(payload, %{
            "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
          })
      })

    case AMQP.Basic.publish(chan, "", @queue, message, persistent: true) do
      :ok ->
        Logger.info("[AMQP.PlayerActionsPublisher] Published action '#{action}' to '#{@queue}'")

      {:error, reason} ->
        Logger.error("[AMQP.PlayerActionsPublisher] Failed to publish: #{inspect(reason)}. Reconnecting...")
        send(self(), :connect)
    end

    {:noreply, chan}
  end
end
