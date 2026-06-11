defmodule BattleRealTimeWeb.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      import Phoenix.ChannelTest
      import BattleRealTimeWeb.ChannelCase

      # The default endpoint for testing
      @endpoint BattleRealTimeWeb.Endpoint
    end
  end

  setup _tags do
    :ok
  end
end
