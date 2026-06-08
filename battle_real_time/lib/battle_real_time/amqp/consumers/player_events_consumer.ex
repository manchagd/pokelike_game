defmodule BattleRealTime.AMQP.Consumers.PlayerEventsConsumer do
  @moduledoc """
  Consumes messages from the `player_events` RabbitMQ queue.
  Broadcasts the events to the corresponding player's PubSub topic.
  """
  use BattleRealTime.AMQP.Consumer, queue: "player_events"

  # Match any event name with player name nested in player
  def process_message(event, %{"player" => %{"name" => name}} = data) do
    broadcast_player_info(name, event, data)
  end

  # Match any event name with player name at root
  def process_message(event, %{"name" => name} = data) do
    broadcast_player_info(name, event, data)
  end

  # Catch-all for other payload formats
  def process_message(event, data) do
    Logger.warning("[AMQP.PlayerEventsConsumer] Could not find player name in payload for event '#{event}': #{inspect(data)}")
  end

  # --- Private ---

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
