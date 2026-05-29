defmodule BattleRealTime.AMQP.Consumer do
  @moduledoc """
  Consumes messages from the `battle_events` RabbitMQ queue.
  Each message is parsed as JSON and broadcast via Phoenix.PubSub to
  the topic "battle_events:{battle_id}", which BattleChannel processes
  then relay to connected WebSocket clients.
  """

  use GenServer
  require Logger

  @queue "battle_events"
  @reconnect_interval 5_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
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
            # Declare the queue (idempotent, matches battle_engine config)
            AMQP.Queue.declare(chan, @queue, durable: true)
            AMQP.Basic.consume(chan, @queue, nil, no_ack: true)
            Logger.info("[AMQP.Consumer] Subscribed to queue '#{@queue}'")
            {:noreply, chan}

          {:error, reason} ->
            Logger.error("[AMQP.Consumer] Failed to open channel: #{inspect(reason)}")
            Process.send_after(self(), :connect, @reconnect_interval)
            {:noreply, nil}
        end

      {:error, _} ->
        Process.send_after(self(), :connect, @reconnect_interval)
        {:noreply, nil}
    end
  end

  # Broker confirms consumer registration
  def handle_info({:basic_consume_ok, %{consumer_tag: tag}}, state) do
    Logger.info("[AMQP.Consumer] Registered as consumer #{tag}")
    {:noreply, state}
  end

  def handle_info({:basic_cancel, _meta}, state), do: {:noreply, state}
  def handle_info({:basic_cancel_ok, _meta}, state), do: {:noreply, state}

  # Main delivery handler
  def handle_info({:basic_deliver, payload, _meta}, state) do
    process_message(payload)
    {:noreply, state}
  end

  # --- Private ---

  defp process_message(payload) do
    case Jason.decode(payload) do
      {:ok, %{"event" => event, "payload" => data}} ->
        battle_id = Map.get(data, "battle_id", "lobby")
        topic = "battle_events:#{battle_id}"

        Logger.info("[AMQP.Consumer] Broadcasting event '#{event}' to topic '#{topic}'")

        Phoenix.PubSub.broadcast(
          BattleRealTime.PubSub,
          topic,
          {:battle_event, %{event: event, payload: data}}
        )

      {:ok, other} ->
        Logger.warning("[AMQP.Consumer] Unexpected message format: #{inspect(other)}")

      {:error, reason} ->
        Logger.error("[AMQP.Consumer] Invalid JSON: #{inspect(reason)}")
    end
  end
end
