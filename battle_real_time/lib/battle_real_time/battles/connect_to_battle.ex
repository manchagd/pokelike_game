defmodule BattleRealTime.Battles.ConnectToBattle do
  alias BattleRealTime.BattleSession
  alias BattleRealTime.BattleSession.Supervisor, as: BattleSessionSupervisor
  require Logger

  def call(battle_id, player_id, username) do
    case ensure_session_started(battle_id) do
      :ok ->
        register_player_if_needed(battle_id, player_id, username)

      error ->
        error
    end
  end

  defp ensure_session_started(battle_id) do
    case BattleSessionSupervisor.find_session(battle_id) do
      {:error, :not_found} ->
        Logger.info("Starting new BattleSession for battle:#{battle_id}")

        case BattleSessionSupervisor.start_session(battle_id) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          error -> error
        end

      {:ok, _pid} ->
        Logger.info("BattleSession for battle:#{battle_id} already exists")
        :ok
    end
  end

  defp register_player_if_needed(battle_id, player_id, username) do
    if player_id != nil and player_id != "" do
      case BattleSession.register_player(battle_id, player_id, username) do
        :ok ->
          {:ok, %{battle_id: battle_id}}

        {:error, :not_found} ->
          {:error, :battle_not_found}

        error ->
          error
      end
    else
      {:ok, %{battle_id: battle_id}}
    end
  end
end
