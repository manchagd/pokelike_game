defmodule BattleRealTime.Battles.Forfeit do
  alias BattleRealTime.BattleSession

  def call(_battle_id, player_id) when player_id in [nil, ""] do
    {:error, :invalid_player}
  end

  def call(battle_id, player_id) do
    BattleSession.forfeit(battle_id, player_id)
    :ok
  end
end
