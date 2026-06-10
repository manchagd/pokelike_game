defmodule BattleRealTime.AMQP.Consumers.PlayerEventsConsumer do
  @moduledoc """
  Consumes messages from the `player_events` RabbitMQ queue.
  Broadcasts the events to the corresponding player's PubSub topic.
  """
  use BattleRealTime.AMQP.Consumer, queue: "player_events"

  def process_message("info" = event, data) do
    case BattleRealTime.Contracts.Consumers.PlayerEvents.InfoContract.validate(data) do
      {:ok, validated_data} ->
        name = validated_data.player.name
        broadcast_player_info(name, event, validated_data)

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
              opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
            end)
          end)

        Logger.error(
          "[AMQP.PlayerEventsConsumer] Inbound contract validation failed for event '#{event}': #{inspect(errors)}"
        )
    end
  end

  def process_message(event, data) do
    Logger.warning(
      "[AMQP.PlayerEventsConsumer] Invalid or unstructured payload for event '#{event}': #{inspect(data)}"
    )
  end

  defp broadcast_player_info(name, event, data) do
    topic = "player:#{name}"
    Logger.info("[AMQP.PlayerEventsConsumer] Broadcasting event '#{event}' to topic '#{topic}'")

    Phoenix.PubSub.broadcast(
      BattleRealTime.PubSub,
      topic,
      {:player_event, %{event: event, payload: data}}
    )
  end
end
