defmodule BattleRealTime.AMQP.Consumers.BattleEventsConsumer do
  @moduledoc """
  Consumes messages from the `battle_events` RabbitMQ queue.
  Each message is parsed as JSON and broadcast via Phoenix.PubSub to
  the topic "battle_events:{battle_id}", which BattleChannel processes
  then relay to connected WebSocket clients.
  """
  use BattleRealTime.AMQP.Consumer, queue: "battle_events"

  def process_message(event, data) do
    battle_id = Map.get(data, "battle_id", "lobby")
    topic = "battle_events:#{battle_id}"

    Logger.info("Broadcasting event '#{event}' to topic '#{topic}'")

    Phoenix.PubSub.broadcast(
      BattleRealTime.PubSub,
      topic,
      {:battle_event, %{event: event, payload: data}}
    )
  end
end
