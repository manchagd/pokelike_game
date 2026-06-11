defmodule BattleRealTime.Contracts.Consumers.PlayerEvents.InfoContractTest do
  use ExUnit.Case, async: true
  alias BattleRealTime.Contracts.Consumers.PlayerEvents.InfoContract
  alias BattleRealTime.Contracts.Contract

  describe "validate/1" do
    test "returns {:ok, map} with valid, fully populated parameters" do
      params = %{
        "player" => %{
          "id" => 101,
          "name" => "Mancha",
          "team" => "A",
          "teams" => [
            %{
              "name" => "Equipo Fuego",
              "description" => "Estrategia basada en fuego",
              "monsters" => [
                %{"name" => "Charizard", "color" => "fire"},
                %{"name" => "Arcanine", "color" => "fire"}
              ]
            }
          ],
          "battle_history" => %{
            "victories" => 5,
            "defeats" => 2,
            "history" => ["V", "V", "D", "V", "D"]
          }
        },
        "battles" => [
          %{
            "id" => "1",
            "opponent" => [
              %{"name" => "player_x", "team" => "A"}
            ]
          }
        ]
      }

      assert {:ok, result} = InfoContract.validate(params)
      assert result.player.id == 101
      assert result.player.name == "Mancha"
      assert result.player.team == "A"
      assert hd(result.player.teams).name == "Equipo Fuego"
      assert hd(hd(result.player.teams).monsters).name == "Charizard"
      assert result.player.battle_history.victories == 5
      assert hd(result.battles).id == "1"
      assert hd(hd(result.battles).opponent).name == "player_x"
    end

    test "returns {:ok, map} with minimum valid parameters (no battles or optional fields)" do
      params = %{
        "player" => %{
          "id" => 42,
          "name" => "SimplePlayer",
          "battle_history" => %{
            "victories" => 0,
            "defeats" => 0
          }
        }
      }

      assert {:ok, result} = InfoContract.validate(params)
      assert result.player.id == 42
      assert result.player.name == "SimplePlayer"
      assert result.player.battle_history.victories == 0
      assert result.battles == []
    end

    test "returns {:error, changeset} when player structure is missing" do
      params = %{}
      assert {:error, changeset} = InfoContract.validate(params)
      assert %{player: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns {:error, changeset} when required player fields are missing" do
      params = %{
        "player" => %{
          "name" => "NoIdPlayer"
        }
      }
      assert {:error, changeset} = InfoContract.validate(params)
      errors = errors_on(changeset)
      assert errors.player.id == ["can't be blank"]
      assert errors.player.battle_history == ["can't be blank"]
    end

    test "returns {:error, changeset} when types are mismatched" do
      params = %{
        "player" => %{
          "id" => "invalid_integer_id",
          "name" => "TypeMismatchPlayer",
          "battle_history" => %{
            "victories" => "not_an_int",
            "defeats" => 0
          }
        }
      }
      assert {:error, changeset} = InfoContract.validate(params)
      errors = errors_on(changeset)
      assert errors.player.id == ["is invalid"]
      assert errors.player.battle_history.victories == ["is invalid"]
    end
  end

  # Helper to extract Ecto errors
  defp errors_on(changeset) do
    Contract.format_errors(changeset)
  end
end
