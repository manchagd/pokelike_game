defmodule BattleRealTime.AMQP.Connection do
  @moduledoc """
  Maintains a single AMQP connection to RabbitMQ.
  Monitors the connection and reconnects automatically on failure.
  Consumer and Publisher open their own channels from this connection.
  """

  use GenServer
  require Logger

  @reconnect_interval 5_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec get :: {:ok, AMQP.Connection.t()} | {:error, :not_connected}
  def get do
    GenServer.call(__MODULE__, :get)
  end

  # --- Callbacks ---

  @impl true
  def init(_) do
    send(self(), :connect)
    {:ok, nil}
  end

  @impl true
  def handle_call(:get, _from, nil) do
    {:reply, {:error, :not_connected}, nil}
  end

  def handle_call(:get, _from, conn) do
    {:reply, {:ok, conn}, conn}
  end

  @impl true
  def handle_info(:connect, _state) do
    url = Application.fetch_env!(:battle_real_time, :rabbitmq_url)

    case AMQP.Connection.open(url) do
      {:ok, conn} ->
        Process.monitor(conn.pid)
        Logger.info("[AMQP.Connection] Connected to RabbitMQ")
        # Notify Consumer and Publisher to (re)connect their channels
        notify_children(:connect)
        {:noreply, conn}

      {:error, reason} ->
        Logger.error(
          "[AMQP.Connection] Failed to connect: #{inspect(reason)}. Retrying in #{@reconnect_interval}ms"
        )

        Process.send_after(self(), :connect, @reconnect_interval)
        {:noreply, nil}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, _state) do
    Logger.error("[AMQP.Connection] Connection lost (#{inspect(reason)}). Reconnecting...")
    Process.send_after(self(), :connect, @reconnect_interval)
    {:noreply, nil}
  end

  # --- Private ---

  defp notify_children(:connect) do
    for child <- [
          BattleRealTime.AMQP.Consumers.BattleEventsConsumer,
          BattleRealTime.AMQP.Publishers.BattleActionsPublisher,
          BattleRealTime.AMQP.Consumers.PlayerEventsConsumer,
          BattleRealTime.AMQP.Publishers.PlayerActionsPublisher
        ] do
      if pid = Process.whereis(child) do
        send(pid, :connect)
      end
    end
  end
end
