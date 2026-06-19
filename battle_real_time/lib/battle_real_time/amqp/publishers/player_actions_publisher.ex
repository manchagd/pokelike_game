defmodule BattleRealTime.AMQP.Publishers.PlayerActionsPublisher do
  @moduledoc """
  Publishes player action messages to the `player_actions` RabbitMQ queue.
  """
  use BattleRealTime.AMQP.Publisher, queue: "player_actions"

  alias BattleRealTime.Contracts.Publishers.PlayerActions.RegisterContract
  alias BattleRealTime.Contracts.Publishers.PlayerActions.CreateBattleContract
  alias BattleRealTime.Contracts.Publishers.PlayerActions.JoinBattleContract
  alias BattleRealTime.Contracts.Publishers.PlayerActions.GetPokemonTemplatesContract
  alias BattleRealTime.Contracts.Publishers.PlayerActions.GetPokemonTemplateMovesContract
  alias BattleRealTime.Contracts.Publishers.PlayerActions.CreateTeamContract
  alias BattleRealTime.Contracts.Publishers.PlayerActions.GetTeamDetailsContract
  alias BattleRealTime.Contracts.Publishers.PlayerActions.DeleteTeamContract

  @impl true
  def validate("register", payload), do: RegisterContract.validate(payload)
  def validate("create_battle", payload), do: CreateBattleContract.validate(payload)
  def validate("join_battle", payload), do: JoinBattleContract.validate(payload)

  def validate("get_pokemon_templates", payload),
    do: GetPokemonTemplatesContract.validate(payload)

  def validate("get_pokemon_template_moves", payload),
    do: GetPokemonTemplateMovesContract.validate(payload)

  def validate("create_team", payload), do: CreateTeamContract.validate(payload)
  def validate("get_team_details", payload), do: GetTeamDetailsContract.validate(payload)
  def validate("delete_team", payload), do: DeleteTeamContract.validate(payload)
  def validate(action, payload), do: super(action, payload)
end
