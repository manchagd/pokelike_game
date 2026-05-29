defmodule BattleRealTimeWeb.UserSocket do
  use Phoenix.Socket

  # Route all "battle:*" topics to BattleChannel
  channel "battle:*", BattleRealTimeWeb.BattleChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    # No authentication for now — accept all connections
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end
