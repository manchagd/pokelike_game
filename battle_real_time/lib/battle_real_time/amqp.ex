defmodule BattleRealTime.AMQP do
  @moduledoc """
  Configuración compartida y utilidades para AMQP.
  """

  @doc """
  Retorna la lista de procesos (publishers y consumers) de AMQP
  que deben ser supervisados.
  """
  def children do
    [
      BattleRealTime.AMQP.Consumers.BattleEventsConsumer,
      BattleRealTime.AMQP.Publishers.BattleActionsPublisher,
      BattleRealTime.AMQP.Consumers.PlayerEventsConsumer,
      BattleRealTime.AMQP.Publishers.PlayerActionsPublisher
    ]
  end
end
