defmodule Mix.Tasks.Utils do
  @moduledoc false

  def format_msec(msec) do
    cond do
      msec < 60_000 -> "#{msec / 1_000} seconds"
      msec < 3600_000 -> "#{msec / 60_000} minutes"
      true -> "#{msec / 3600_000} hours"
    end
  end

  def fail(message) do
    error(message)
    exit({:shutdown, 1})
  end

  def error(message, %Ecto.Changeset{} = changeset) when is_binary(message) do
    changeset_errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    error(message, changeset_errors)
  end

  def error(message, data) when is_binary(message), do: error("#{message}: " <> inspect(data))

  def error(message) when is_binary(message), do: IO.puts(IO.ANSI.red() <> message)

  def error(message), do: error(inspect(message))

  def ok(message), do: IO.puts(IO.ANSI.green() <> message)

  def progress(message, :no_newline), do: IO.write(IO.ANSI.yellow() <> "\r#{message}")

  def progress(message), do: IO.puts(IO.ANSI.yellow() <> message)
end
