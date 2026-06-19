defmodule BattleRealTime.Players.GetPokemonTemplateMoves do
  alias BattleRealTime.AMQP.Publishers.PlayerActionsPublisher

  def call(player_id, _pokemon_template_id) when player_id in [nil, ""] do
    {:error, :invalid_player}
  end

  def call(_player_id, pokemon_template_id) when pokemon_template_id in [nil, ""] do
    {:error, :invalid_template}
  end

  def call(player_id, pokemon_template_id) do
    payload = %{"player_id" => player_id, "pokemon_template_id" => pokemon_template_id}

    case PlayerActionsPublisher.publish("get_pokemon_template_moves", payload) do
      :ok -> {:ok, payload}
      error -> error
    end
  end
end
