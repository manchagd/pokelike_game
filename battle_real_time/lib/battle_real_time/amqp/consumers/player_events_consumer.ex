defmodule BattleRealTime.AMQP.Consumers.PlayerEventsConsumer do
  @moduledoc """
  Consumes messages from the `player_events` RabbitMQ queue.
  Broadcasts the events to the corresponding player's PubSub topic.
  """
  use BattleRealTime.AMQP.Consumer, queue: "player_events"

  def process_message(payload) do
    case Jason.decode(payload) do
      {:ok, %{"event" => event, "payload" => data}} ->
        player_name =
          case data do
            %{"player" => %{"name" => name}} -> name
            %{"name" => name} -> name
            _ -> nil
          end

        if player_name do
          topic = "player:#{player_name}"
          Logger.info("[AMQP.PlayerEventsConsumer] Broadcasting event '#{event}' to topic '#{topic}'")

          Phoenix.PubSub.broadcast(
            BattleRealTime.PubSub,
            topic,
            {:player_event, %{event: event, payload: data}}
          )
        else
          Logger.warning("[AMQP.PlayerEventsConsumer] Could not find player name in payload: #{inspect(data)}")
        end

      {:ok, other} ->
        Logger.warning("[AMQP.PlayerEventsConsumer] Unexpected message format: #{inspect(other)}")

      {:error, reason} ->
        Logger.error("[AMQP.PlayerEventsConsumer] Invalid JSON: #{inspect(reason)}")
    end
  end
end
