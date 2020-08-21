defmodule Stockcast.Prices do
  alias Stockcast.IexCloud.HistoricalPrices, as: IexPrices

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
      trades with prices over time
  """
  @spec trade([%{date: Date.t(), price: decimal()}], :perfect | :naive, Keyword.t()) ::
          %{profit: decimal(), strategy: [%{date: Date.t(), action: :sell | :buy}]}
          | {:error, any()}
  def trade(prices, mode, opts \\ []) do
    opts = Keyword.merge([short_selling: false], opts)

    case mode do
      :naive -> naive_trading(prices)
      :perfect -> perfect_trading(prices, opts)
      _ -> {:error, :invalid_mode}
    end
  end

  defp naive_trading(prices) do
    %{
      profit: Decimal.sub(List.last(prices).price, List.first(prices).price),
      strategy: [
        %{
          date: List.first(prices).date,
          action: :buy
        },
        %{
          date: List.last(prices).date,
          action: :sell
        }
      ]
    }
  end

  defp perfect_trading(prices, opts) do
    prices
    |> Enum.dedup_by(&Decimal.to_string(&1.price))
    |> Enum.chunk_every(3, 1)
    |> Enum.with_index()
    |> Enum.flat_map(&find_minima_and_maxima/1)
    |> Enum.chunk_every(2, 1)
    |> Enum.reduce(
      %{strategy: [], profit: Decimal.new(0), opts: opts},
      &update_trading/2
    )
    |> Map.update!(:strategy, &Enum.reverse/1)
    |> Map.delete(:opts)
  end

  defp find_minima_and_maxima({[p1, p2, p3], i}) do
    min_max =
      if Decimal.cmp(p2.price, Decimal.max(p1.price, p3.price)) == :gt ||
           Decimal.cmp(p2.price, Decimal.min(p1.price, p3.price)) == :lt do
        [p2]
      else
        []
      end

    if i == 0 do
      [p1 | min_max]
    else
      min_max
    end
  end

  defp find_minima_and_maxima({[_, p], _}), do: [p]

  defp update_trading(
         [%{price: p1, date: d1}, %{price: p2, date: _}],
         %{strategy: strategy, profit: profit, opts: [short_selling: short_selling]} = state
       ) do
    if Decimal.cmp(p1, p2) == :gt do
      profit =
        if short_selling do
          Decimal.add(profit, Decimal.sub(p1, p2))
        else
          profit
        end

      %{state | strategy: [%{date: d1, action: :sell} | strategy], profit: profit}
    else
      %{
        state
        | strategy: [%{date: d1, action: :buy} | strategy],
          profit: Decimal.add(profit, Decimal.sub(p2, p1))
      }
    end
  end

  defp update_trading(
         [%{date: d}],
         %{strategy: strategy} = state
       ) do
    %{state | strategy: [%{date: d, action: :sell} | strategy]}
  end
end
