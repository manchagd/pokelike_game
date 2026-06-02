defmodule Mix.Tasks.Amqp.Publish.Attack do
  @shortdoc "Publishes an 'attack' message to the battle_actions queue"

  @moduledoc """
  Publishes an attack event to the `battle_actions` RabbitMQ queue.

  ## Default payload

      {
        "event": "attack",
        "payload": {
          "battle_id": "42",
          "trainer_id": "1",
          "move_id": "85",
          "target_positions": ["1", "2"]
        }
      }

  ## Usage

      mix amqp.publish.attack
      mix amqp.publish.attack battle_id=99 trainer_id=2 move_id=10 target_positions=0,1
  """
  alias Mix.Tasks.AmqpPublishHelpers, as: Helper
  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    args = Helper.parse_args(argv)

    payload = %{
      "battle_id" => Map.get(args, "battle_id", "42"),
      "trainer_id" => Map.get(args, "trainer_id", "1"),
      "move_id" => Map.get(args, "move_id", "85"),
      "target_positions" => parse_positions(Map.get(args, "target_positions", "1,2"))
    }

    Mix.shell().info("[amqp.publish.attack] Publishing → #{inspect(payload)}")
    Helper.publish!("attack", payload)
    Mix.shell().info("[amqp.publish.attack] ✓ Published")
  end

  # Splits a comma-separated string into a list of trimmed strings.
  defp parse_positions(str) do
    str |> String.split(",") |> Enum.map(&String.trim/1)
  end
end
