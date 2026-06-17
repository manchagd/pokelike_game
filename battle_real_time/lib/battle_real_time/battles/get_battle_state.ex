defmodule BattleRealTime.Battles.GetBattleState do
  @moduledoc """
  Domain use case to retrieve the public state payload of a battle session.
  """
  alias BattleRealTime.BattleSession

  @spec call(String.t()) :: {:ok, map()} | {:error, any()}
  def call(battle_id) do
    case BattleSession.get_state_payload(battle_id) do
      {:ok, payload} ->
        {:ok, payload}

      {:error, :not_found} ->
        {:error, :battle_not_found}

      error ->
        error
    end
  end
end
