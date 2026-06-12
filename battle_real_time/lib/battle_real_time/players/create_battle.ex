defmodule BattleRealTime.Players.CreateBattle do
  alias BattleRealTime.AMQP.Publishers.PlayerActionsPublisher

  def call(player_id, team_id \\ 1)

  def call(player_id, _team_id) when player_id in [nil, ""] do
    {:error, :invalid_player}
  end

  def call(player_id, team_id) do
    payload = %{"player_id" => player_id, "team_id" => team_id}

    case PlayerActionsPublisher.publish("create_battle", payload) do
      :ok -> {:ok, payload}
      error -> error
    end
  end
end
