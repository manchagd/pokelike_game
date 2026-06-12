defmodule BattleRealTime.AMQP.Consumers.PlayerEventsConsumer do
  @moduledoc """
  Consumes messages from the `player_events` RabbitMQ queue.
  Broadcasts the events to the corresponding player's PubSub topic.
  """
  use BattleRealTime.AMQP.Consumer, queue: "player_events"

  alias BattleRealTime.Contracts.Consumers.PlayerEvents.InfoContract
  alias BattleRealTime.Contracts.Consumers.PlayerEvents.BattleCreatedContract
  alias BattleRealTime.Contracts.Consumers.PlayerEvents.BattleJoinedContract
  alias BattleRealTime.Contracts.Contract

  def process_message("info" = event, data) do
    case InfoContract.validate(data) do
      {:ok, validated_data} ->
        name = validated_data.player.name
        broadcast_player_info(name, event, validated_data)

      {:error, changeset} ->
        errors = Contract.format_errors(changeset)

        Logger.error(
          "Inbound contract validation failed for event '#{event}': #{inspect(errors)}"
        )
    end
  end

  def process_message("battle_created" = event, data) do
    case BattleCreatedContract.validate(data) do
      {:ok, validated_data} ->
        player_id = validated_data.player_id
        broadcast_player_event(player_id, event, validated_data)

      {:error, changeset} ->
        errors = Contract.format_errors(changeset)

        Logger.error(
          "Inbound contract validation failed for event '#{event}': #{inspect(errors)}"
        )
    end
  end

  def process_message("battle_joined" = event, data) do
    case BattleJoinedContract.validate(data) do
      {:ok, validated_data} ->
        player_id = validated_data.player_id
        broadcast_player_event(player_id, event, validated_data)

      {:error, changeset} ->
        errors = Contract.format_errors(changeset)

        Logger.error(
          "Inbound contract validation failed for event '#{event}': #{inspect(errors)}"
        )
    end
  end

  def process_message(event, data) do
    Logger.warning("Invalid or unstructured payload for event '#{event}': #{inspect(data)}")
  end

  defp broadcast_player_info(name, event, data) do
    topic = "player:#{name}"
    Logger.info("Broadcasting event '#{event}' to topic '#{topic}'")

    Phoenix.PubSub.broadcast(
      BattleRealTime.PubSub,
      topic,
      {:player_event, %{event: event, payload: data}}
    )
  end

  defp broadcast_player_event(player_id, event, data) do
    topic = "player:#{player_id}"
    Logger.info("Broadcasting event '#{event}' to topic '#{topic}'")

    Phoenix.PubSub.broadcast(
      BattleRealTime.PubSub,
      topic,
      {:player_event, %{event: event, payload: data}}
    )
  end
end
