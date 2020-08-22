defmodule Stockcast.PricesTest do
  use Stockcast.DataCase

  import Mock
  import Stockcast.TestUtils

  alias Stockcast.Prices

  @symbol "00XP-GY"
  @date_from ~D[2020-04-02]
  @date_to ~D[2020-04-15]

  setup do
    prices = store_prices()
    [prices: prices]
  end

  test "retrieve/4 returns prices", %{prices: prices} do
    {:ok, retrieved_prices} = Prices.retrieve(@symbol, @date_from, @date_to)

    assert retrieved_prices == prices
  end

  test "retrieve/4 returns sampled", %{prices: prices} do
    {:ok, retrieved_prices} = Prices.retrieve(@symbol, @date_from, @date_to, 2)

    assert retrieved_prices == Enum.take_every(prices, 2)
  end

  describe "when to date is omitted" do
    test_with_mock "retrieve/4 uses yesterday", %{prices: prices}, Date, [:passthrough],
      utc_today: fn -> ~D[2020-04-16] end do
      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @date_from)

      assert retrieved_prices == prices
    end
  end

  test "trade/1 (1)" do
    assert [50, 100, 40, 200]
           |> for_trade()
           |> Prices.trade() == %{
             performance: Decimal.cast(200 - 50),
             trading: Decimal.cast(50 + 160),
             short_trading: Decimal.cast(50 + 60 + 160),
             strategy: [
               {~D[2020-01-01], :buy},
               {~D[2020-01-02], :sell},
               {~D[2020-01-03], :buy},
               {~D[2020-01-04], :sell}
             ]
           }
  end

  test "trade/1 (2)" do
    assert [50, 100]
           |> for_trade()
           |> Prices.trade() == %{
             performance: Decimal.cast(100 - 50),
             trading: Decimal.cast(50),
             short_trading: Decimal.cast(50),
             strategy: [{~D[2020-01-01], :buy}, {~D[2020-01-02], :sell}]
           }
  end

  test "trade/1 (3)" do
    assert [100, 50]
           |> for_trade()
           |> Prices.trade() == %{
             performance: Decimal.cast(50 - 100),
             trading: Decimal.cast(0),
             short_trading: Decimal.cast(50),
             strategy: [{~D[2020-01-01], :sell}, {~D[2020-01-02], :buy}]
           }
  end

  test "trade/1 (4)" do
    assert [100]
           |> for_trade()
           |> Prices.trade() == %{
             performance: Decimal.cast(0),
             trading: Decimal.cast(0),
             short_trading: Decimal.cast(0),
             strategy: []
           }
  end

  test "trade/1 (5)" do
    assert []
           |> for_trade()
           |> Prices.trade() == %{
             performance: Decimal.cast(0),
             trading: Decimal.cast(0),
             short_trading: Decimal.cast(0),
             strategy: []
           }
  end

  test "trade/1 perfect (6)" do
    assert [50, 100, 90, 40, 110, 200]
           |> for_trade()
           |> Prices.trade() == %{
             trading: Decimal.cast(50 + 160),
             short_trading: Decimal.cast(50 + 60 + 160),
             performance: Decimal.cast(200 - 50),
             strategy: [
               {~D[2020-01-01], :buy},
               {
                 ~D[2020-01-02],
                 :sell
               },
               {
                 ~D[2020-01-04],
                 :buy
               },
               {
                 ~D[2020-01-06],
                 :sell
               }
             ]
           }
  end

  defp for_trade(prices) do
    Enum.with_index(prices)
    |> Enum.map(fn {price, i} ->
      %{
        price: Decimal.cast(price),
        date: Date.add(~D[2020-01-01], i)
      }
    end)
  end
end
