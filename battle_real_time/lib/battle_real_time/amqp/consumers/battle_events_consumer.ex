defmodule BattleRealTime.AMQP.Consumers.BattleEventsConsumer do
  @moduledoc """
  Consumes messages from the `battle_events` RabbitMQ queue.
  Each message is parsed as JSON and broadcast via Phoenix.PubSub to
  the topic "battle_events:{battle_id}", which BattleChannel processes
  then relay to connected WebSocket clients.
  """
  use BattleRealTime.AMQP.Consumer, queue: "battle_events"

  alias BattleRealTime.Contracts.Consumers.BattleEvents.BattleStatusContract
  alias BattleRealTime.Contracts.Consumers.BattleEvents.MutateBattleStatusContract
  alias BattleRealTime.Contracts.Contract

  def process_message("mutate_battle_status", data) do
    case MutateBattleStatusContract.validate(data) do
      {:ok, %{status: "finished"} = valid_data} ->
        battle_id = Map.get(valid_data, :battle_id)
        reason = Map.get(valid_data, :reason, "")

        Logger.info(
          "Received mutate_battle_status (finished) from RabbitMQ. Terminating GenServer session for battle: #{battle_id}"
        )

        case BattleRealTime.BattleSession.terminate_session(battle_id, reason) do
          :ok ->
            Logger.info(
              "GenServer session for battle #{battle_id} terminated. Broadcasting battle_ended."
            )

            BattleRealTime.BattleSession.broadcast_battle_ended(battle_id, reason)

          {:error, :not_found} ->
            Logger.warning("Attempted to terminate non-existent battle session: #{battle_id}")
            BattleRealTime.BattleSession.broadcast_battle_ended(battle_id, reason)
        end

      {:ok, valid_data} ->
        Logger.warning("Unexpected status transition for battle: #{inspect(valid_data)}")

      {:error, changeset} ->
        Logger.error(
          "Validation failed for event 'mutate_battle_status': #{inspect(Contract.format_errors(changeset))}"
        )
    end
  end

  def process_message("battle_status", data) do
    case BattleStatusContract.validate(data) do
      {:ok, valid_data} ->
        battle_id = Map.get(valid_data, :external_id)

        Logger.info(
          "Received battle_status from RabbitMQ. Syncing GenServer state for battle: #{battle_id}"
        )

        case BattleRealTime.BattleSession.sync_state(battle_id, data) do
          :ok ->
            :ok

          {:error, :not_found} ->
            Logger.warning(
              "Attempted to sync state for non-existent battle session: #{battle_id}"
            )
        end

      {:error, changeset} ->
        Logger.error(
          "Validation failed for event 'battle_status': #{inspect(Contract.format_errors(changeset))}"
        )
    end
  end

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
