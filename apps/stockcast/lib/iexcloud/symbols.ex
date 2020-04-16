defmodule Stockcast.IexCloud.Symbols do
  require Logger

  alias Stockcast.IexCloud.Api
  alias Stockcast.IexCloud.Symbol

  alias Stockcast.Repo

  @chunk_size 100

  @spec fetch(String.t(), (String.t() -> any())) ::
          {:ok, %{fetched: integer(), saved: integer()}} | {:error, any()}
  def fetch(symbol_path, progress_callback \\ fn _ -> nil end)
      when is_binary(symbol_path) and is_function(progress_callback) do
    case Api.get_data(symbol_path) do
      {:ok, symbols} when is_list(symbols) ->
        progress_callback.({:ok, %{fetched: length(symbols)}})

        {:ok,
         %{fetched: length(symbols), saved: save_symbols_chunked(symbols, progress_callback)}}

      {:ok, _} ->
        {:error, :empty_body}

      error ->
        error
    end
  end

  defp save_symbols_chunked(symbols, progress_callback) do
    symbols
    |> Enum.chunk_every(@chunk_size)
    |> Enum.reduce(0, fn chunked_symbols, saved_so_far ->
      saved = save_symbols(chunked_symbols, progress_callback)
      progress_callback.({:ok, %{saved: saved_so_far + saved, total: length(symbols)}})
      saved_so_far + saved
    end)
  end

  defp save_symbols(symbols, progress_callback) do
    symbols
    |> Enum.map(&save_symbol/1)
    |> Enum.count(fn
      {:ok, _} ->
        true

      {:error, changeset} ->
        progress_callback.({:error, changeset})
        false
    end)
  end

  defp save_symbol(symbol_data) when is_map(symbol_data) do
    symbol_data
    |> parse_symbol_data
    |> Symbol.changeset()
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
