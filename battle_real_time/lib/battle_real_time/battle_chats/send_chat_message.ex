defmodule BattleRealTime.BattleChats.SendChatMessage do
  def call(player_id, username, body) when is_binary(body) do
    if String.trim(body) != "" do
      message_payload = %{
        "body" => body,
        "username" => username,
        "player_id" => player_id,
        "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
      }

      {:ok, message_payload}
    else
      {:error, :invalid_body}
    end
  end

  def call(_player_id, _username, _body) do
    {:error, :invalid_body}
  end
end
