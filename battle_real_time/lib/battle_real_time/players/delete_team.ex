defmodule BattleRealTime.Players.DeleteTeam do
  alias BattleRealTime.AMQP.Publishers.PlayerActionsPublisher

  def call(player_id, team_id) do
    payload = %{
      "player_id" => player_id,
      "team_id" => team_id
    }

    case PlayerActionsPublisher.publish("delete_team", payload) do
      :ok -> {:ok, payload}
      error -> error
    end
  end
end
