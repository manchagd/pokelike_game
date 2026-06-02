defmodule Mix.Tasks.Amqp.Publish.Change do
  @shortdoc "Publishes a 'change' (Pokémon switch) message to the battle_actions queue"

  @moduledoc """
  Publishes a Pokémon change event to the `battle_actions` RabbitMQ queue.

  ## Default payload

      {
        "event": "change",
        "payload": {
          "battle_id": "42",
          "trainer_id": "1",
          "pokemon_in_id": "9",
          "pokemon_out_id": "25"
        }
      }

  ## Usage

      mix amqp.publish.change
      mix amqp.publish.change battle_id=99 trainer_id=2 pokemon_in_id=6 pokemon_out_id=4
  """
  alias Mix.Tasks.AmqpPublishHelpers, as: Helper
  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    args = Helper.parse_args(argv)

    payload = %{
      battle_id: Map.get(args, "battle_id", "42"),
      trainer_id: Map.get(args, "trainer_id", "1"),
      pokemon_in_id: Map.get(args, "pokemon_in_id", "9"),
      pokemon_out_id: Map.get(args, "pokemon_out_id", "25")
    }

    Mix.shell().info("[amqp.publish.change] Publishing → #{inspect(payload)}")
    Helper.publish!("change", payload)
    Mix.shell().info("[amqp.publish.change] ✓ Published")
  end
end
