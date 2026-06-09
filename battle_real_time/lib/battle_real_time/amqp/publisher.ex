defmodule BattleRealTime.AMQP.Publisher do
  @moduledoc """
  A behavior module that provides standard boilerplate for AMQP publishers.
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

      @doc """
      Publishes an action to the queue.
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
                Logger.info("[#{inspect(__MODULE__)}] Ready to publish to queue '#{@queue}'")
                {:noreply, chan}

              {:error, reason} ->
                Logger.error("[#{inspect(__MODULE__)}] Failed to open channel: #{inspect(reason)}")
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
        Logger.error("[#{inspect(__MODULE__)}] Not connected to RabbitMQ — dropping message")
        {:noreply, nil}
      end

      @impl true
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
            Logger.info("[#{inspect(__MODULE__)}] Published action '#{action}' to '#{@queue}'")

          {:error, reason} ->
            Logger.error("[#{inspect(__MODULE__)}] Failed to publish: #{inspect(reason)}. Reconnecting...")
            send(self(), :connect)
        end

        {:noreply, chan}
      end

      defoverridable start_link: 1, publish: 2, init: 1, handle_info: 2, handle_cast: 2
    end
  end
end
