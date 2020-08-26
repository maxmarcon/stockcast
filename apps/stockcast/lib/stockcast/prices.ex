defmodule Stockcast.Prices do
  alias Stockcast.IexCloud.HistoricalPrices, as: IexPrices
  alias Stockcast.Performance
  alias Stockcast.IexCloud.HistoricalPrice

  @type decimal :: Decimal.t()

  @doc ~S"""
  retrieve stock prices for a particular symbol
  """
  @spec retrieve(binary(), Date.t(), %Date{}) ::
          {:ok, [%{}]} | {:error, atom()}
  def retrieve(symbol, from, to \\ Date.add(Date.utc_today(), -1), sampling \\ 1)
      when is_binary(symbol) and is_integer(sampling) and sampling >= 1,
      do: IexPrices.retrieve(symbol, from, to, sampling)

  @doc ~S"""
      trades with prices over time, returns performance of stocks
  """
  @spec trade([%{date: Date.t(), price: decimal()}]) :: Performance.t()
  def trade(prices) when is_list(prices) and length(prices) > 0 do
    prices
    |> Stream.dedup_by(&Decimal.to_string(&1.price))
    |> Stream.chunk_every(3, 1)
    |> Stream.with_index()
    |> Stream.flat_map(&find_minima_and_maxima/1)
    |> Stream.chunk_every(2, 1)
    |> Enum.reduce(%Performance{}, &update_trading/2)
    |> Map.update!(:strategy, &Enum.reverse/1)
    |> Map.put(:raw, Decimal.sub(List.last(prices).price, List.first(prices).price))
  end

  def trade([]), do: %Performance{}

  @spec trade_from_historical_prices([HistoricalPrice.t()]) :: Performance.t()
  def trade_from_historical_prices(historical_prices) do
    historical_prices
    |> Enum.map(fn %{close: price, date: date} -> %{price: price, date: date} end)
    |> trade
  end

  defp find_minima_and_maxima({[p1, p2, p3], i}) when i == 0 do
    [p1 | min_max(p1, p2, p3)]
  end

  defp find_minima_and_maxima({[p1, p2, p3], _}), do: min_max(p1, p2, p3)

  defp find_minima_and_maxima({[p1, p2], 0}), do: [p1, p2]

  defp find_minima_and_maxima({[_, p], _}), do: [p]

  defp find_minima_and_maxima({[_], _}), do: []

  defp min_max(p1, p2, p3) do
    if Decimal.cmp(p2.price, Decimal.max(p1.price, p3.price)) == :gt ||
         Decimal.cmp(p2.price, Decimal.min(p1.price, p3.price)) == :lt do
      [p2]
    else
      []
    end
  end

  defp update_trading(
         [%{price: p1, date: d1}, %{price: p2, date: _}],
         %{strategy: strategy, trading: trading, short_trading: short_trading} = state
       ) do
    if Decimal.cmp(p1, p2) == :gt do
      %{
        state
        | strategy: [{d1, :sell} | strategy],
          short_trading: Decimal.add(short_trading, Decimal.sub(p1, p2))
      }
    else
      profit = Decimal.sub(p2, p1)

      %{
        state
        | strategy: [{d1, :buy} | strategy],
          trading: Decimal.add(trading, profit),
          short_trading: Decimal.add(short_trading, profit)
      }
    end
  end

  defp update_trading(
         [%{date: d}],
         %{strategy: [{_, :sell} | _] = strategy} = state
       ) do
    %{state | strategy: [{d, :buy} | strategy]}
  end

  defp update_trading(
         [%{date: d}],
         %{strategy: [{_, :buy} | _] = strategy} = state
       ) do
    %{state | strategy: [{d, :sell} | strategy]}
  end
end
