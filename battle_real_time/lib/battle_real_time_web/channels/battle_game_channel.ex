defmodule BattleRealTimeWeb.BattleGameChannel do
  use Phoenix.Channel
  require Logger

  @impl true
  def join("battle_game", _params, socket) do
    Logger.info("[BattleGameChannel] Client joined battle_game")
    {:ok, socket}
  end

  @impl true
  def handle_in("register", %{"name" => name}, socket) do
    Logger.info("[BattleGameChannel] Registering player: #{name}")
    # Publish to the player_actions queue via PlayerActionsPublisher
    BattleRealTime.AMQP.PlayerActionsPublisher.publish("register", %{"name" => name})
    {:noreply, socket}
  end

  @impl true
  def handle_in(event, _payload, socket) do
    Logger.warning("[BattleGameChannel] Unknown event: #{event}")
    {:noreply, socket}
  end
end
