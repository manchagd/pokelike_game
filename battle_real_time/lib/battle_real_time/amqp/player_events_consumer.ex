defmodule BattleRealTime.AMQP.PlayerEventsConsumer do
  @moduledoc """
  Consumes messages from the `player_events` RabbitMQ queue.
  Broadcasts the events to the corresponding player's PubSub topic.
  """

  use GenServer
  require Logger

  @queue "player_events"
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
            AMQP.Queue.declare(chan, @queue, durable: true)
            AMQP.Basic.consume(chan, @queue, nil, no_ack: true)
            Logger.info("[AMQP.PlayerEventsConsumer] Subscribed to queue '#{@queue}'")
            {:noreply, chan}

          {:error, reason} ->
            Logger.error("[AMQP.PlayerEventsConsumer] Failed to open channel: #{inspect(reason)}")
            Process.send_after(self(), :connect, @reconnect_interval)
            {:noreply, nil}
        end

      {:error, _} ->
        Process.send_after(self(), :connect, @reconnect_interval)
        {:noreply, nil}
    end
  end

  # Broker confirms consumer registration
  @impl true
  def handle_info({:basic_consume_ok, %{consumer_tag: tag}}, state) do
    Logger.info("[AMQP.PlayerEventsConsumer] Registered as consumer #{tag}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:basic_cancel, _meta}, state), do: {:noreply, state}
  @impl true
  def handle_info({:basic_cancel_ok, _meta}, state), do: {:noreply, state}

  # Main delivery handler
  @impl true
  def handle_info({:basic_deliver, payload, _meta}, state) do
    process_message(payload)
    {:noreply, state}
  end

  # --- Private ---

  defp process_message(payload) do
    case Jason.decode(payload) do
      {:ok, %{"event" => event, "payload" => data}} ->
        player_name =
          case data do
            %{"player" => %{"name" => name}} -> name
            %{"name" => name} -> name
            _ -> nil
          end

        if player_name do
          topic = "player:#{player_name}"
          Logger.info("[AMQP.PlayerEventsConsumer] Broadcasting event '#{event}' to topic '#{topic}'")

          Phoenix.PubSub.broadcast(
            BattleRealTime.PubSub,
            topic,
            {:player_event, %{event: event, payload: data}}
          )
        else
          Logger.warning("[AMQP.PlayerEventsConsumer] Could not find player name in payload: #{inspect(data)}")
        end

      {:ok, other} ->
        Logger.warning("[AMQP.PlayerEventsConsumer] Unexpected message format: #{inspect(other)}")

      {:error, reason} ->
        Logger.error("[AMQP.PlayerEventsConsumer] Invalid JSON: #{inspect(reason)}")
    end
  end
end
