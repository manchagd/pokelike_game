defmodule Mix.Tasks.AmqpPublishHelpers do
  @moduledoc """
  Shared helpers for `mix amqp.publish.*` tasks.

  Handles argument parsing, application startup, and publishing
  through the existing `BattleRealTime.AMQP.Publisher` GenServer.
  """

  @publisher BattleRealTime.AMQP.Publisher
  @max_retries 10
  @retry_interval 300

  @doc """
  Parses CLI arguments in `key=value` format into a string-keyed map.

  ## Example

      iex> parse_args(["battle_id=42", "trainer_id=1"])
      %{"battle_id" => "42", "trainer_id" => "1"}
  """
  def parse_args(argv) do
    argv
    |> Enum.map(&String.split(&1, "=", parts: 2))
    |> Enum.filter(&match?([_, _], &1))
    |> Map.new(fn [k, v] -> {k, v} end)
  end

  @doc """
  Starts the application, waits for the Publisher to be ready,
  publishes the event, and gives the async cast time to complete.
  """
  def publish!(event, payload) do
    Mix.Task.run("app.start")
    wait_for_publisher(@max_retries)

    @publisher.publish(event, payload)

    # Allow the GenServer cast to flush before the VM shuts down
    Process.sleep(500)
  end

  # Polls until the Publisher GenServer is registered and alive.
  defp wait_for_publisher(0) do
    Mix.raise("Publisher not available — is RabbitMQ running?")
  end

  defp wait_for_publisher(retries) do
    case GenServer.whereis(@publisher) do
      nil ->
        Process.sleep(@retry_interval)
        wait_for_publisher(retries - 1)

      _pid ->
        :ok
    end
  end
end
