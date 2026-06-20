defmodule BattleRealTime.Players.GetPokemonTemplates do
  alias BattleRealTime.AMQP.Publishers.PlayerActionsPublisher

  def call(player_id) when player_id in [nil, ""] do
    {:error, :invalid_player}
  end

  def call(player_id) do
    payload = %{"player_id" => player_id}

    case PlayerActionsPublisher.publish("get_pokemon_templates", payload) do
      :ok -> {:ok, payload}
      error -> error
    end
  end
end
