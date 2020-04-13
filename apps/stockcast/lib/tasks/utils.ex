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

  def error(message) do
    IO.puts(IO.ANSI.red() <> message)
  end

  def ok(message) do
    IO.puts(IO.ANSI.green() <> message)
  end
end
