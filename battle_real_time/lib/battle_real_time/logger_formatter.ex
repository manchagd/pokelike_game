defmodule BattleRealTime.LoggerFormatter do
  @moduledoc """
  Custom formatter for Elixir's Logger.
  Automatically prepends the module alias to all log messages.
  For modules containing "AMQP" in their namespace, it prepends "[AMQP.Alias]".
  For other modules, it prepends "[Alias]".
  """

  @spec format(atom, Logger.message(), Logger.Formatter.date_time_ms(), keyword) :: IO.chardata()
  def format(level, message, timestamp, metadata) do
    # 1. Format the message with the module alias prepended
    message = prepend_module_alias(message, metadata)

    # 2. Delete :module from metadata to prevent standard formatter from printing it
    metadata = Keyword.delete(metadata, :module)

    # 3. Get the compiled format pattern
    pattern = get_compiled_pattern()

    # 4. Format using Elixir's standard formatter
    Logger.Formatter.format(pattern, level, message, timestamp, metadata)
  end

  defp get_compiled_pattern do
    case :persistent_term.get({__MODULE__, :pattern}, nil) do
      nil ->
        config = Application.get_env(:logger, :default_formatter, [])
        pattern_str = Keyword.get(config, :pattern, "$time $metadata[$level] $message\n")
        compiled = Logger.Formatter.compile(pattern_str)
        :persistent_term.put({__MODULE__, :pattern}, compiled)
        compiled

      compiled ->
        compiled
    end
  end

  defp prepend_module_alias(message, metadata) do
    case Keyword.get(metadata, :module) do
      nil ->
        message

      module when is_atom(module) ->
        module_str = Atom.to_string(module)

        if String.starts_with?(module_str, "Elixir.BattleRealTime") do
          alias_name =
            case String.split(module_str, ".") do
              ["Elixir" | rest] ->
                last = List.last(rest)

                if Enum.member?(rest, "AMQP") do
                  "AMQP.#{last}"
                else
                  last
                end

              parts ->
                last = List.last(parts)

                if Enum.member?(parts, "AMQP") do
                  "AMQP.#{last}"
                else
                  last
                end
            end

          case alias_name do
            nil -> message
            "" -> message
            # Prepend formatted alias in brackets to the message chardata
            name -> ["[", name, "] ", message]
          end
        else
          message
        end
    end
  end
end
