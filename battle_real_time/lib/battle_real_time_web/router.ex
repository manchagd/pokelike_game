defmodule BattleRealTimeWeb.Router do
  use BattleRealTimeWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BattleRealTimeWeb do
    pipe_through :api

    get "/health", HealthController, :index
  end
end
