defmodule Stockcast.IexCloud.HistoricalPrices do
  import Ecto.Query

  alias Stockcast.Repo
  alias Stockcast.IexCloud.HistoricalPrice, as: Price
  alias Stockcast.IexCloud.Api

  @data_fraction_thr 0.95
  @time_thr 86400
  @ranges [
    [range: "1m", days: 30],
    [range: "3m", days: 30 * 3],
    [range: "6m", days: 30 * 6],
    [range: "1y", days: 365],
    [range: "2y", days: 365 * 2],
    [range: "5y", days: 365 * 5]
  ]

  @spec retrieve(binary(), Date.t(), %Date{}) ::
          {:ok, [%Price{}]} | {:error, atom()}
  def retrieve(symbol, from, to) when is_binary(symbol) do
    with :lt <- Date.compare(from, to),
         :lt <- Date.compare(to, Date.utc_today()) do
      case maybe_fetch_prices(symbol, from, to) do
        :ok -> {:ok, price_query(symbol, from, to) |> Repo.all()}
        error -> error
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
        _ in Ecto.InvalidChangesetError -> raise "the IexCloud API returned some invalid data"
      end
    else
      true -> :ok
      other -> other
    end
  end

  defp prices_locally_available(symbol, from, to) do
    wanted = Date.range(from, to) |> Enum.count(&is_weekday/1)
    available = Repo.aggregate(price_query(symbol, from, to), :count)
    available >= @data_fraction_thr * wanted
  end

  defp prices_fetchable(from) do
    days_to_fetch = Date.diff(Date.utc_today(), from)

    case Enum.find(@ranges, fn [range: _, days: days] ->
           days >= days_to_fetch
         end) do
      [range: range, days: _] -> {:ok, range}
      _ -> {:error, :too_old}
    end
  end

  defp fetch_prices(symbol, range) do
    case Api.get_data("/stock/#{symbol}/chart/#{range}") do
      {:ok, prices} when is_list(prices) -> save_prices(symbol, prices)
      error -> error
    end
  end

  defp save_prices(symbol, prices) do
    prices
    |> Enum.map(&Map.put_new(&1, "symbol", symbol))
    |> Enum.map(&Price.changeset/1)
    |> Enum.each(
      &Repo.insert!(&1,
        on_conflict: {:replace_all_except, [:inserted_at]},
        conflict_target: [:symbol, :date]
      )
    )
  end

  defp is_weekday(date), do: Date.day_of_week(date) in [1, 2, 3, 4, 5]

  defp price_query(symbol, from, to) do
    from p in Price,
      where:
        p.symbol == ^symbol and
          p.date <= ^to and
          p.date >= ^from,
      order_by: p.date
  end
end
