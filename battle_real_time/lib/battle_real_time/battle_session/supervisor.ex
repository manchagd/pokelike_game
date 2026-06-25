defmodule BattleRealTime.BattleSession.Supervisor do
  use Supervisor

  @registry BattleRealTime.BattleSession.Registry
  @dynamic_supervisor BattleRealTime.BattleSession.DynamicSupervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Registry, keys: :unique, name: @registry},
      {DynamicSupervisor, name: @dynamic_supervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # --- API Pública ---

  @doc """
  Devuelve el nombre del registro utilizado para las tuplas `:via`.
  """
  def registry_name, do: @registry

  @doc """
  Inicia una nueva sesión de batalla bajo el DynamicSupervisor.
  """
  def start_session(battle_id) do
    DynamicSupervisor.start_child(@dynamic_supervisor, {BattleRealTime.BattleSession, battle_id})
  end

  @doc """
  Busca el PID de una sesión de batalla por su ID.
  """
  def find_session(battle_id) do
    case Registry.lookup(@registry, battle_id) do
      [{pid, _value}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end
end
