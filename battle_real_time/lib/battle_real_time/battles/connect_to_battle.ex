defmodule BattleRealTime.Battles.ConnectToBattle do
  alias BattleRealTime.BattleSession
  require Logger

  def call(battle_id, player_id, username) do
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
    |> case do
      :ok ->
        if player_id != nil and player_id != "" do
          BattleSession.register_player(battle_id, player_id, username)
        end

        {:ok, %{battle_id: battle_id}}

      error ->
        error
    end
  end
end
