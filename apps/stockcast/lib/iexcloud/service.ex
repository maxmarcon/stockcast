defmodule Stockcast.IexCloud.Service do
  alias Stockcast.IexCloud.Api
  alias Stockcast.IexCloud.Symbol
  alias Stockcast.Repo

  @spec fetch_symbols(String.t()) :: {:ok, integer()}
  def fetch_symbols(symbol_path) do
    saved =
      Api.get(symbol_path)
      |> Enum.count(fn symbol_data ->
        case save_symbol(symbol_data) do
          {:ok, _} -> true
          _ -> false
        end
      end)

    {:ok, saved}
  end

  defp save_symbol(symbol_data) when is_map(symbol_data) do
    Repo.insert(Symbol.changeset(%Symbol{}, parse_symbol_data(symbol_data)),
      on_conflict: :replace_all,
      conflict_target: :iex_id
    )
  end

  defp parse_symbol_data(symbol_data) do
    symbol_data
    |> Map.put("iex_id", symbol_data["iexId"])
  end
end
