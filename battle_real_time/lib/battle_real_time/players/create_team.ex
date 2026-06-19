defmodule BattleRealTime.Players.CreateTeam do
  alias BattleRealTime.AMQP.Publishers.PlayerActionsPublisher

  def call(player_id, _name, _pokemons) when player_id in [nil, ""] do
    {:error, :invalid_player}
  end

  def call(_player_id, name, _pokemons) when name in [nil, ""] do
    {:error, :invalid_name}
  end

  def call(_player_id, _name, pokemons) when not is_list(pokemons) or length(pokemons) == 0 do
    {:error, :invalid_pokemons}
  end

  def call(player_id, name, pokemons, team_id \\ nil) do
    payload = %{
      "player_id" => player_id,
      "name" => name,
      "pokemons" => pokemons,
      "team_id" => team_id
    }

    case PlayerActionsPublisher.publish("create_team", payload) do
      :ok -> {:ok, payload}
      error -> error
    end
  end
end
