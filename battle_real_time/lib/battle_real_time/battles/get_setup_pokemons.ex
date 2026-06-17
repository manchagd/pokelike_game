defmodule BattleRealTime.Battles.GetSetupPokemons do
  @moduledoc """
  Domain use case to retrieve the list of setup pokemons for a specific player in a battle.
  """
  alias BattleRealTime.BattleSession

  @spec call(String.t(), String.t()) :: {:ok, list(map())} | {:error, any()}
  def call(_battle_id, player_id) when player_id in [nil, ""] do
    {:error, :invalid_player}
  end

  def call(battle_id, player_id) do
    case BattleSession.get_state(battle_id) do
      {:ok, state} ->
        player_data =
          Enum.find(state.players_data, fn p ->
            (p["id"] && to_string(p["id"]) == player_id) ||
              p["name"] == Map.get(state.player_names, player_id)
          end)

        if player_data && player_data["pokemons"] do
          {:ok, player_data["pokemons"]}
        else
          {:error, :no_pokemons}
        end

      {:error, :not_found} ->
        {:error, :battle_not_found}

      error ->
        error
    end
  end
end
