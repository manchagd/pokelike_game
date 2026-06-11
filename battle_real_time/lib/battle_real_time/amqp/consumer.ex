defmodule BattleRealTime.AMQP.Consumer do
  @moduledoc """
  A behavior module that provides standard boilerplate for AMQP consumers.
  """

  defmacro __using__(opts) do
    queue = Keyword.fetch!(opts, :queue)

    quote do
      use GenServer
      require Logger

      @queue unquote(queue)
      @reconnect_interval 5_000

      def start_link(init_opts \\ []) do
        GenServer.start_link(__MODULE__, init_opts, name: __MODULE__)
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
                # Declare the queue (idempotent)
                AMQP.Queue.declare(chan, @queue, durable: true)
                # Register consumer
                AMQP.Basic.consume(chan, @queue, nil, no_ack: true)
                Logger.info("Subscribed to queue '#{@queue}'")
                {:noreply, chan}

              {:error, reason} ->
                Logger.error("Failed to open channel: #{inspect(reason)}")
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
        Logger.info("Registered as consumer #{tag}")
        {:noreply, state}
      end

      @impl true
      def handle_info({:basic_cancel, _meta}, state), do: {:noreply, state}
      @impl true
      def handle_info({:basic_cancel_ok, _meta}, state), do: {:noreply, state}

      # Main delivery handler
      @impl true
      def handle_info({:basic_deliver, payload, _meta}, state) do
        consume!(payload)
        {:noreply, state}
      end

      def consume!(payload) do
        case Jason.decode(payload) do
          {:ok, %{"event" => event, "payload" => data}} ->
            process_message(event, data)

          {:ok, other} ->
            Logger.warning("Unexpected message format: #{inspect(other)}")

          {:error, reason} ->
            Logger.error("Invalid JSON: #{inspect(reason)}")
        end
      end

      defoverridable start_link: 1, init: 1, handle_info: 2, consume!: 1
    end
  end
end
