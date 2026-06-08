defmodule BattleRealTime.AMQP.BattleActionsPublisher do
  @moduledoc """
  Publishes player action messages to the `battle_actions` RabbitMQ queue.
  battle_engine consumes from this queue and applies business logic.
  """

  use GenServer
  require Logger

  @queue "battle_actions"
  @reconnect_interval 5_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Publishes an action to the battle_actions queue.
  The payload map must include "battle_id".
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
            Logger.info("[AMQP.BattleActionsPublisher] Ready to publish to queue '#{@queue}'")
            {:noreply, chan}

          {:error, reason} ->
            Logger.error("[AMQP.BattleActionsPublisher] Failed to open channel: #{inspect(reason)}")
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
    Logger.error("[AMQP.BattleActionsPublisher] Not connected to RabbitMQ — dropping message")
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
        Logger.info("[AMQP.BattleActionsPublisher] Published action '#{action}' to '#{@queue}'")

      {:error, reason} ->
        Logger.error("[AMQP.BattleActionsPublisher] Failed to publish: #{inspect(reason)}. Reconnecting...")
        send(self(), :connect)
    end

    {:noreply, chan}
  end
end
