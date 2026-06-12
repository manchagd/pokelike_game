defmodule BattleRealTime.Battles.ConnectToBattle do
  alias BattleRealTime.BattleSession
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
    case Registry.lookup(BattleRealTime.BattleRegistry, battle_id) do
      [] ->
        Logger.info("Starting new BattleSession for battle:#{battle_id}")

        case DynamicSupervisor.start_child(
               BattleRealTime.BattleSupervisor,
               {BattleSession, battle_id}
             ) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          error -> error
        end

      _ ->
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
