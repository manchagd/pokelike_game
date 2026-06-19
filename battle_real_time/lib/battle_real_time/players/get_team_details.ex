defmodule BattleRealTime.Players.GetTeamDetails do
  alias BattleRealTime.AMQP.Publishers.PlayerActionsPublisher

  def call(player_id, team_id) do
    payload = %{
      "player_id" => player_id,
      "team_id" => team_id
    }

    case PlayerActionsPublisher.publish("get_team_details", payload) do
      :ok -> {:ok, payload}
      error -> error
    end
  end
end
