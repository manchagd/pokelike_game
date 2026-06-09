defmodule BattleRealTimeWeb.Presence do
  use Phoenix.Presence,
    otp_app: :battle_real_time,
    pubsub_server: BattleRealTime.PubSub
end
