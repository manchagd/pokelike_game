defmodule BattleRealTime.AMQP.Consumers.PlayerEventsConsumer do
  @moduledoc """
  Consumes messages from the `player_events` RabbitMQ queue.
  Broadcasts the events to the corresponding player's PubSub topic.
  """
  use BattleRealTime.AMQP.Consumer, queue: "player_events"

  def process_message(event, %{"player" => %{"id" => id, "name" => name}} = data)
      when not is_nil(id) and not is_nil(name) do
    broadcast_player_info(name, event, data)
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
