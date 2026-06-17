defmodule BattleRealTime.Players.JoinBattle do
  alias BattleRealTime.AMQP.Publishers.PlayerActionsPublisher

  def call(player_id, battle_id, team_id \\ nil)

  def call(player_id, _battle_id, _team_id) when player_id in [nil, ""] do
    {:error, :invalid_player}
  end

  def call(_player_id, battle_id, _team_id) when battle_id in [nil, ""] do
    {:error, :invalid_battle}
  end

  def call(_player_id, _battle_id, team_id) when team_id in [nil, ""] do
    {:error, :invalid_team}
  end

  def call(player_id, battle_id, team_id) do
    amqp_payload = %{"player_id" => player_id, "battle_id" => battle_id, "team_id" => team_id}

    case PlayerActionsPublisher.publish("join_battle", amqp_payload) do
      :ok -> {:ok, amqp_payload}
      error -> error
    end
  end
end
