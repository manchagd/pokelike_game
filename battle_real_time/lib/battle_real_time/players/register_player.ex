defmodule BattleRealTime.Players.RegisterPlayer do
  alias BattleRealTime.AMQP.Publishers.PlayerActionsPublisher

  def call(name) when is_binary(name) do
    if String.trim(name) != "" do
      PlayerActionsPublisher.publish("register", %{"name" => name})
      :ok
    else
      {:error, :invalid_player_name}
    end
  end

  def call(_name) do
    {:error, :invalid_player_name}
  end
end
