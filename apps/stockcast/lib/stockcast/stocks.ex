defmodule Stockcast.Stocks do
  @moduledoc """
  To search for stocks
  """

  import Ecto.Query, warn: false
  alias Stockcast.Repo
  alias Stockcast.IexCloud.Symbol, as: IexSymbol
  alias Stockcast.IexCloud.Isin, as: IexIsin
  alias Stockcast.IexCloud.Isins, as: IexIsins

  @isin_format ~r/^[A-Z]{2}\w{9}\d$/

  @doc ~S"""
  search stocks by term. this could be:

    1. A part of the symbol name
    2. A prefix of the symbol ID (including the entire symbol)
    3. An ISIN
  """
  @spec search(binary(), integer()) :: [%IexSymbol{}]
  def search(term, limit \\ 100)
      when is_binary(term) and is_integer(limit) do
    term_list = String.split(term)

    Repo.all(from iex_cloud_search(term_list), limit: ^limit)
    |> Repo.preload(:isins)
  end

  defp iex_cloud_search(term_list) do
    term_list
    |> Enum.each(&iex_cloud_maybe_fetch_isins/1)

    query =
      from s in IexSymbol,
        distinct: true,
        left_join: assoc(s, :isins),
        order_by: [s.symbol, s.iex_id]

    term_list
    |> Enum.reduce(query, fn term, query ->
      prefix_like_exp = "#{term}%"
      infix_like_exp = "%#{term}%"

      from [s, i] in query,
        where:
          ilike(s.symbol, ^prefix_like_exp) or
            ilike(s.name, ^infix_like_exp) or
            ilike(s.figi, ^prefix_like_exp) or
            ilike(i.isin, ^prefix_like_exp)
    end)
  end

  @doc ~S"""
  find stocks by ID. At the moment only supports IexCloud IDs
  """
  @spec get(binary()) :: %IexSymbol{} | nil
  def get(id), do: Repo.get_by(IexSymbol, iex_id: id) |> Repo.preload(:isins)

  @doc ~S"""
  find stocks by ID, throws if none found. At the moment only supports IexCloud IDs
  """
  @spec get(binary()) :: %IexSymbol{}
  def get!(id), do: Repo.get_by!(IexSymbol, iex_id: id) |> Repo.preload(:isins)

  @doc ~S"""
  find stocks by symbol.
  """
  @spec get_by_symbol(binary()) :: %IexSymbol{} | nil
  def get_by_symbol(symbol), do: Repo.get_by(IexSymbol, symbol: symbol) |> Repo.preload(:isins)

  @doc ~S"""
  find stocks by symbol, throws if none found.
  """
  @spec get_by_symbol!(binary()) :: %IexSymbol{} | nil
  def get_by_symbol!(symbol), do: Repo.get_by!(IexSymbol, symbol: symbol) |> Repo.preload(:isins)

  defp iex_cloud_maybe_fetch_isins(term) do
    upcase_term = String.upcase(term)

    if Regex.match?(@isin_format, upcase_term) &&
         !Repo.exists?(from IexIsin, where: [isin: ^upcase_term]) do
      IexIsins.fetch!(upcase_term)
    end
  end
end
