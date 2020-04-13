defmodule Stockcast.IexCloud.Symbols do
  require Logger

  alias Stockcast.IexCloud.Api
  alias Stockcast.IexCloud.Symbol

  alias Stockcast.Repo

  @spec fetch(String.t(), (String.t() -> any())) ::
          {:ok, %{fetched: integer(), saved: integer()}} | {:error, any()}
  def fetch(symbol_path, progress_callback \\ fn _ -> nil end)
      when is_binary(symbol_path) and is_function(progress_callback) do
    case Api.call_api_and_process_request(:get, symbol_path) do
      {:ok, symbols} ->
        progress_callback.({:ok, "fetched #{length(symbols)} symbols"})
        {:ok, %{fetched: length(symbols), saved: save_symbols(symbols, progress_callback)}}

      error ->
        error
    end
  end

  defp save_symbols(symbols, progress_callback) do
    symbols
    |> Enum.map(&save_symbol/1)
    |> Enum.count(fn
      {:ok, _} ->
        true

      {:error, %{errors: errors}} ->
        progress_callback.({:error, "error while saving symbol: #{inspect(errors)}"})
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

  defp parse_symbol_data(symbol_data) do
    symbol_data
    |> Map.put("iex_id", symbol_data["iexId"])
    |> Map.delete("iexId")
  end
end
