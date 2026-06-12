defmodule BattleRealTime.Battles.Forfeit do
  alias BattleRealTime.BattleSession

  def call(_battle_id, player_id) when player_id in [nil, ""] do
    {:error, :invalid_player}
  end

  def call(battle_id, player_id) do
    case BattleSession.forfeit(battle_id, player_id) do
      :ok ->
        :ok

      {:error, :not_found} ->
        {:error, :battle_not_found}

      error ->
        error
    end
  end
end
