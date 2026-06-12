defmodule BattleRealTime.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        BattleRealTimeWeb.Telemetry,
        {DNSCluster,
         query: Application.get_env(:battle_real_time, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: BattleRealTime.PubSub},
        {Registry, keys: :unique, name: BattleRealTime.BattleRegistry},
        {DynamicSupervisor, name: BattleRealTime.BattleSupervisor, strategy: :one_for_one},
        BattleRealTime.AMQP.Connection
      ] ++
        BattleRealTime.AMQP.children() ++
        [
          BattleRealTimeWeb.Presence,
          BattleRealTimeWeb.Endpoint
        ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BattleRealTime.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BattleRealTimeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
