defmodule BattleRealTimeWeb.ApplicationChannel do
  use Phoenix.Channel
  alias BattleRealTimeWeb.Presence
  require Logger

  @impl true
  def join("application", _params, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    # Track the current socket process under the "lobby" key
    {:ok, _} =
      Presence.track(socket, "lobby", %{
        online_at: System.system_time(:second)
      })

    # Send the initial presence list to the client
    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end
end
