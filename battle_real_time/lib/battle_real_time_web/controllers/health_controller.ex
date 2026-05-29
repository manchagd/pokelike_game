defmodule BattleRealTimeWeb.HealthController do
  use BattleRealTimeWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok", app: "battle_real_time"})
  end
end
