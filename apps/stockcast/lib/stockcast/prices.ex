defmodule Stockcast.Prices do
  alias Stockcast.IexCloud.HistoricalPrices, as: IexHistoricalPrices
  alias Stockcast.Performance
  alias Stockcast.IexCloud.HistoricalPrice

  import Decimal

  @type decimal :: Decimal.t()

  @doc ~S"""
  retrieve historical stock prices for a particular symbol
  """
  @spec retrieve_historical_prices(binary(), Date.t(), %Date{}) ::
          {:ok, [%{}]} | {:error, atom()}
  def retrieve_historical_prices(
        symbol,
        from,
        to \\ Date.add(Date.utc_today(), -1),
        sampling \\ 1
      )
      when is_binary(symbol) and is_integer(sampling) and sampling >= 1,
      do: IexHistoricalPrices.retrieve(symbol, from, to, sampling)

  @doc ~S"""
      trades with prices over time, returns performance of stocks
  """
  @spec trade([%{date: Date.t(), price: decimal()}]) :: Performance.t()
  def trade(prices) when is_list(prices) and length(prices) > 0 do
    strategy =
      prices
      |> Stream.dedup_by(&Decimal.to_string(&1.price))
      |> Stream.chunk_every(3, 1)
      |> Stream.with_index()
      |> Stream.flat_map(&find_minima_and_maxima/1)
      |> Stream.chunk_every(2, 1)
      |> Enum.reduce([], &update_strategy/2)

    last_action =
      List.first(strategy) || %{balance: Decimal.cast(0), balance_short: Decimal.cast(0)}

    %Performance{
      trading: last_action.balance,
      short_trading: last_action.balance_short,
      baseline: List.first(prices).price,
      raw: Decimal.sub(List.last(prices).price, List.first(prices).price),
      strategy: Enum.reverse(strategy)
    }
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

  defp sell(
         price,
         date,
         strategy,
         last \\ false
       )

  defp sell(
         price,
         date,
         strategy = [%{balance: balance, balance_short: balance_short} | _],
         true
       ) do
    [
      %{
        date: date,
        price: price,
        action: :sell,
        balance: add(balance, price),
        balance_short:
          add(
            balance_short,
            price
          )
      }
      | strategy
    ]
  end

  defp sell(
         price,
         date,
         strategy = [%{balance: balance, balance_short: balance_short} | _],
         false
       ) do
    [
      %{
        date: date,
        price: price,
        action: :sell,
        balance: add(balance, price),
        balance_short:
          add(
            balance_short,
            mult(2, price)
          )
      }
      | strategy
    ]
  end

  defp sell(price, date, [], _last) do
    [
      %{
        date: date,
        price: price,
        action: :sell,
        balance: Decimal.cast(0),
        balance_short: add(0, price)
      }
    ]
  end

  defp buy(price, date, strategy, last \\ false)

  defp buy(price, date, strategy = [%{balance: balance, balance_short: balance_short} | _], false) do
    [
      %{
        date: date,
        price: price,
        action: :buy,
        balance: sub(balance, price),
        balance_short: sub(balance_short, mult(2, price))
      }
      | strategy
    ]
  end

  defp buy(price, date, strategy = [%{balance: balance, balance_short: balance_short} | _], true) do
    [
      %{
        date: date,
        price: price,
        action: :buy,
        balance: balance,
        balance_short: sub(balance_short, price)
      }
      | strategy
    ]
  end

  defp buy(price, date, [], false) do
    [
      %{
        date: date,
        price: price,
        action: :buy,
        balance: sub(0, price),
        balance_short: sub(0, price)
      }
    ]
  end

  defp update_strategy(
         [%{price: p1, date: d1}, %{price: p2, date: _}],
         strategy
       ) do
    if cmp(p1, p2) == :gt do
      sell(p1, d1, strategy)
    else
      buy(p1, d1, strategy)
    end
  end

  defp update_strategy(
         [%{date: d, price: p}],
         [%{action: :sell} | _] = strategy
       ),
       do: buy(p, d, strategy, true)

  defp update_strategy(
         [%{date: d, price: p}],
         [%{action: :buy} | _] = strategy
       ),
       do: sell(p, d, strategy, true)
end
