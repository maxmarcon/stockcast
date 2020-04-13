defmodule Mix.Tasks.Fetch.Symbols do
  @iexcloud "IexCloud"

  @moduledoc ~s"""
  fetches symbols from #{@iexcloud}

    * `symbol_path_1 symbol_path_2` - then names of the symbol paths to fetch

  if paths are omitted, all paths defined in the configuration will be fetched
  """
  @shortdoc "fetches #{@iexcloud} symbols"

  use Mix.Task

  import Mix.Tasks.Utils

  alias Stockcast.IexCloud.Symbols

  @impl Mix.Task
  def run(args) do
    {_, symbol_paths_from_args, _} = OptionParser.parse(args, strict: [])

    start_time = Time.utc_now()

    Application.ensure_all_started(:stockcast)

    summary =
      symbol_paths(symbol_paths_from_args)
      |> Enum.reduce(
        %{fetched: 0, saved: 0},
        fn path, progress ->
          ok("\nfetching: #{path}}")

          case Symbols.fetch(path, &print_progress/1) do
            {:ok, %{fetched: fetched, saved: saved}} ->
              %{fetched: progress.fetched + fetched, saved: progress.saved + saved}

            {:error, error} ->
              error("API error while fetching data: #{inspect(error)}")
              progress
          end
        end
      )

    ok(
      "\nfetched #{summary.fetched} symbols, saved #{summary.saved} in #{
        format_msec(Time.diff(Time.utc_now(), start_time, :millisecond))
      }"
    )
  end

  defp symbol_paths([]) do
    symbol_paths = Access.get(Application.get_env(:stockcast, Symbols, []), :symbol_paths)

    if is_nil(symbol_paths) || !is_list(symbol_paths) || Enum.empty?(symbol_paths) do
      fail(
        "You need to specify a list of symbol paths, either in the configuration or in the command line arguments"
      )
    end

    ok("fetching all symbol paths from the configuration")
    symbol_paths
  end

  defp symbol_paths(from_args) when is_list(from_args) do
    ok("fetching the following symbol paths: #{inspect(from_args)}")
    from_args
  end

  defp print_progress({:ok, %{fetched: fetched}}) do
    ok("fetched #{fetched} symbols")
  end

  defp print_progress({:ok, %{saved: saved, total: total}}) do
    IO.write(
      IO.ANSI.cyan() <> "\rsaved #{saved} symbols (#{Float.round(100 * saved / total, 0)}%)"
    )
  end

  defp print_progress({:ok, message}) do
    ok(message)
  end

  defp print_progress({:error, %{changes: changes, errors: errors}}) do
    error("error saving symbol #{inspect(changes)}: #{inspect(errors)}")
  end
end
