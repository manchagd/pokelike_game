defmodule BattleRealTime.Players.RequestJoinBattle do
  alias BattleRealTime.AMQP.Publishers.PlayerActionsPublisher

  def call(player_id, battle_id, team_id \\ 1)

  def call(player_id, _battle_id, _team_id) when player_id in [nil, ""] do
    {:error, :invalid_player}
  end

  def call(_player_id, battle_id, _team_id) when battle_id in [nil, ""] do
    {:error, :invalid_battle}
  end

  def call(player_id, battle_id, team_id) do
    amqp_payload = %{"player_id" => player_id, "battle_id" => battle_id, "team_id" => team_id}
    PlayerActionsPublisher.publish("join_battle", amqp_payload)
    {:ok, amqp_payload}
  end
end
