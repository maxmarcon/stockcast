defmodule Stockcast.IexCloud.Symbols do
  require Logger

  alias Stockcast.IexCloud.Api
  alias Stockcast.IexCloud.Symbol
  alias Stockcast.Repo

  @spec fetch_symbols(String.t()) :: {:ok, integer()} | any()
  def fetch_symbols(symbol_path) do
    case Api.fetch(:get, symbol_path) do
      {:ok, symbol_list} -> {:ok, save_symbols(symbol_list)}
      error -> error
    end
  end

  @spec fetch_symbols() :: integer()
  def fetch_symbols() do
    Enum.reduce(
      Access.get(Application.get_env(:stockcast, __MODULE__, []), :symbol_paths) ||
        raise("You need to specify a list of symbol paths"),
      0,
      fn symbol_path, saved_so_far ->
        case fetch_symbols(symbol_path) do
          {:ok, saved} -> saved + saved_so_far
          _ -> saved_so_far
        end
      end
    )
  end

  defp parse_symbol_data(symbol_data) do
    symbol_data
    |> Map.put("iex_id", symbol_data["iexId"])
    |> Map.delete("iexId")
  end

  defp save_symbols(symbols) do
    Logger.info("retrieved #{length(symbols)} symbols.")

    symbols
    |> Enum.map(&save_symbol/1)
    |> Enum.count(fn
      {:ok, _} ->
        true

      {:error, %{errors: errors}} ->
        Logger.error(errors)
        false
    end)
  end

  defp save_symbol(symbol_data) when is_map(symbol_data) do
    symbol_data
    |> parse_symbol_data
    |> Symbol.changeset_insert()
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:inserted_at]},
      conflict_target: :iex_id
    )
  end
end
