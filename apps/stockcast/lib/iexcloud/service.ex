defmodule Stockcast.IexCloud.Service do
  alias Stockcast.IexCloud.Api
  alias Stockcast.IexCloud.Symbol
  alias Stockcast.Repo

  @spec fetch_symbols(String.t()) :: {:ok, integer()}
  def fetch_symbols(symbol_path) do
    saved =
      Api.get(symbol_path)
      |> Enum.map(&save_symbol/1)
      |> Enum.count(fn
        {:ok, _} -> true
        _ -> false
      end)

    {:ok, saved}
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

  defp parse_symbol_data(symbol_data) do
    symbol_data
    |> Map.put("iex_id", symbol_data["iexId"])
    |> Map.delete("iexId")
  end
end
