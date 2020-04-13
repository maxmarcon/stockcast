defmodule Mix.Tasks.Fetch.Symbols do
  @iexcloud "IexCloud"

  @moduledoc ~s"""
  fetches symbols from #{@iexcloud}

    * `symbol_path_1 symbol_path_2` - then names of the symbol paths to fetch

  if paths are omitted, all paths defined in the configuration will be fetched
  """
  @shortdoc "fetches #{@iexcloud} symbols"

  use Mix.Task

  alias Stockcast.IexCloud.Symbols

  @impl Mix.Task
  def run(args) do
    {_, symbol_paths_from_args, _} = OptionParser.parse(args, strict: [])

    Application.ensure_all_started(:stockcast)

    summary =
      symbol_paths(symbol_paths_from_args)
      |> Enum.reduce(
        %{fetched: 0, saved: 0},
        fn path, %{fetched: fetched, saved: saved} = progress ->
          ok("fetching: #{path}}")

          case Symbols.fetch(path, &print_progress/1) do
            {:ok, %{fetched: newly_fetched, saved: newly_saved}} ->
              %{fetched: fetched + newly_fetched, saved: saved + newly_saved}

            {:error, error} ->
              error("API error while fetching data #{inspect(error)}")
              progress
          end
        end
      )

    ok("fetched #{summary.fetched} symbols, saved #{summary.saved}")
  end

  defp print_progress({:ok, message}) do
    ok(message)
  end

  defp print_progress({:error, message}) do
    error(message)
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

  defp fail(message) do
    error(message)
    exit({:shutdown, 1})
  end

  defp error(message) do
    IO.puts(IO.ANSI.red() <> message)
  end

  defp ok(message) do
    IO.puts(IO.ANSI.green() <> message)
  end
end
