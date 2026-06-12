defmodule BattleRealTime.Battles.SubmitAction do
  alias BattleRealTime.BattleSession

  def call(_battle_id, player_id, _payload) when player_id in [nil, ""] do
    {:error, :invalid_player}
  end

  def call(battle_id, player_id, payload) do
    enriched = payload |> Map.put("battle_id", battle_id) |> Map.put("player_id", player_id)

    case BattleSession.submit_action(battle_id, player_id, enriched) do
      {:ok, _status} ->
        {:ok, enriched}

      {:error, :not_found} ->
        {:error, :battle_not_found}

      error ->
        error
    end
  end
end
