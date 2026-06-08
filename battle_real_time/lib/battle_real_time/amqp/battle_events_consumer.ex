defmodule BattleRealTime.AMQP.BattleEventsConsumer do
  @moduledoc """
  Consumes messages from the `battle_events` RabbitMQ queue.
  Each message is parsed as JSON and broadcast via Phoenix.PubSub to
  the topic "battle_events:{battle_id}", which BattleChannel processes
  then relay to connected WebSocket clients.
  """
  use BattleRealTime.AMQP.Consumer, queue: "battle_events"

  def process_message(payload) do
    case Jason.decode(payload) do
      {:ok, %{"event" => event, "payload" => data}} ->
        battle_id = Map.get(data, "battle_id", "lobby")
        topic = "battle_events:#{battle_id}"

        Logger.info("[AMQP.BattleEventsConsumer] Broadcasting event '#{event}' to topic '#{topic}'")

        Phoenix.PubSub.broadcast(
          BattleRealTime.PubSub,
          topic,
          {:battle_event, %{event: event, payload: data}}
        )

      {:ok, other} ->
        Logger.warning("[AMQP.BattleEventsConsumer] Unexpected message format: #{inspect(other)}")

      {:error, reason} ->
        Logger.error("[AMQP.BattleEventsConsumer] Invalid JSON: #{inspect(reason)}")
    end
  end
end
