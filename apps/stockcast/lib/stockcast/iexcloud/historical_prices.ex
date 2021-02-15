defmodule Stockcast.IexCloud.HistoricalPrices do
  import Ecto.Query

  require Logger

  alias Stockcast.Repo
  alias Stockcast.IexCloud.HistoricalPrice, as: Price
  alias Stockcast.IexCloud.Api

  @data_fraction_thr 0.9
  @min_time_between_calls_ms 6 * 3600 * 1000
  @ranges [
    [range: "1m", days: 30],
    [range: "3m", days: 30 * 3],
    [range: "6m", days: 30 * 6],
    [range: "1y", days: 365],
    [range: "2y", days: 365 * 2],
    [range: "5y", days: 365 * 5]
  ]

  @spec retrieve(binary(), Date.t(), Date.t(), integer()) ::
          {:ok, [%Price{}]} | {:error, atom()}
  def retrieve(symbol, from, to, sampling \\ 1)
      when is_binary(symbol) and is_integer(sampling) and
             sampling >= 1 do
    symbol = String.upcase(symbol)

    with true <- Date.compare(from, to) in [:lt, :eq],
         :lt <- Date.compare(to, Date.utc_today()) do
      case maybe_fetch_prices(symbol, from, to) do
        :ok ->
          {
            :ok,
            price_query(symbol, from, to, sampling)
            |> Repo.all()
          }

        error ->
          error
      end
    else
      _ -> {:error, :invalid_dates}
    end
  end

  defp maybe_fetch_prices(symbol, from, to) do
    with false <- prices_locally_available(symbol, from, to),
         {:ok, range} <- prices_fetchable(from) do
      try do
        fetch_prices(symbol, range)
      rescue
        e in Ecto.InvalidChangesetError -> {:error, e.changeset}
      end
    else
      true -> :ok
      error -> error
    end
  end

  defp log_availability(locally_available, symbol, from, to, wanted, available, needed) do
    msg =
      if locally_available do
        "ARE"
      else
        "ARE NOT"
      end

    Logger.debug(
      "prices for #{symbol} in range (#{from}, #{to}) #{msg} locally available (needed #{
        @data_fraction_thr
      } * #{wanted} = #{needed}, available #{available})"
    )
  end

  defp prices_locally_available(symbol, from, to) do
    wanted =
      Date.range(from, to)
      |> Enum.count(&is_weekday/1)

    available = Repo.aggregate(price_query(symbol, from, to), :count)

    needed = ceil(@data_fraction_thr * wanted)
    locally_available = available >= needed

    log_availability(locally_available, symbol, from, to, wanted, available, needed)
    locally_available
  end

  defp prices_fetchable(from) do
    days_to_fetch = Date.diff(Date.utc_today(), from)

    case Enum.find(
           @ranges,
           fn [range: _, days: days] ->
             days >= days_to_fetch
           end
         ) do
      [range: range, days: _] -> {:ok, range}
      _ -> {:error, :too_old, earliest_fetchable()}
    end
  end

  defp earliest_fetchable() do
    [_, days: days] = List.last(@ranges)

    Date.utc_today()
    |> Date.add(-days)
  end

  defp fetch_prices(symbol, range) do
    url = "/stock/#{symbol}/chart/#{range}"

    with {:ok, false} <- Cachex.exists?(:iex_cloud, url),
         {:ok, true} <- Cachex.put(:iex_cloud, url, true, ttl: @min_time_between_calls_ms),
         {:ok, prices} when is_list(prices) <- Api.get_data(url) do
      save_prices(symbol, prices)
    else
      {:error, 404, _} ->
        {:error, :unknown_symbol}

      {:ok, true} ->
        Logger.debug("prices for #{symbol} for period #{range} not fetched because done recently")
        :ok

      error ->
        error
    end
  end

  defp save_prices(symbol, prices) do
    prices
    |> Enum.map(&Map.put_new(&1, "symbol", symbol))
    |> Enum.map(&Price.changeset/1)
    |> Enum.each(
      &Repo.insert!(
        &1,
        on_conflict: {:replace_all_except, [:inserted_at]},
        conflict_target: [:symbol, :date]
      )
    )
  end

  defp is_weekday(date), do: Date.day_of_week(date) in [1, 2, 3, 4, 5]

  defp price_query(symbol, from, to, sampling \\ 1) do
    query =
      from p in Price,
        select: %{
          id: p.id,
          rank: over(rank(), order_by: p.date) - 1
        },
        where:
          p.symbol == ^symbol and
            p.date <= ^to and
            p.date >= ^from

    from p in Price,
      join: s in subquery(query),
      on: p.id == s.id and fragment("? % ? = 0", s.rank, ^sampling),
      order_by: p.date
  end
end
