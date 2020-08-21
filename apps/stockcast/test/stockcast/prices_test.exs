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

  test "trade/3 error" do
    assert [50, 100, 40, 25]
           |> for_trade()
           |> Prices.trade(:foo) == {:error, :invalid_mode}
  end

  test "trade/3 naive (1)" do
    assert [50, 100, 40, 200]
           |> for_trade()
           |> Prices.trade(:naive) == %{
             profit: Decimal.cast(150),
             strategy: [
               %{
                 date: ~D[2020-01-01],
                 action: :buy
               },
               %{
                 date: ~D[2020-01-04],
                 action: :sell
               }
             ]
           }
  end

  test "trade/3 naive (2)" do
    assert [50, 100, 40, 25]
           |> for_trade()
           |> Prices.trade(:naive) == %{
             profit: Decimal.cast(-25),
             strategy: [
               %{
                 date: ~D[2020-01-01],
                 action: :buy
               },
               %{
                 date: ~D[2020-01-04],
                 action: :sell
               }
             ]
           }
  end

  test "trede/3 perfect (1)" do
    assert [50, 100, 40, 200]
           |> for_trade()
           |> Prices.trade(:perfect) == %{
             profit: Decimal.cast(50 + 160),
             strategy: [
               %{
                 date: ~D[2020-01-01],
                 action: :buy
               },
               %{
                 date: ~D[2020-01-02],
                 action: :sell
               },
               %{
                 date: ~D[2020-01-03],
                 action: :buy
               },
               %{
                 date: ~D[2020-01-04],
                 action: :sell
               }
             ]
           }
  end

  test "trede/3 perfect (2)" do
    assert [50, 100, 40, 200]
           |> for_trade()
           |> Prices.trade(:perfect, short_selling: true) == %{
             profit: Decimal.cast(50 + 60 + 160),
             strategy: [
               %{
                 date: ~D[2020-01-01],
                 action: :buy
               },
               %{
                 date: ~D[2020-01-02],
                 action: :sell
               },
               %{
                 date: ~D[2020-01-03],
                 action: :buy
               },
               %{
                 date: ~D[2020-01-04],
                 action: :sell
               }
             ]
           }
  end

  test "trede/3 perfect (3)" do
    assert [50, 100, 90, 40, 110, 200]
           |> for_trade()
           |> Prices.trade(:perfect, short_selling: true) == %{
             profit: Decimal.cast(50 + 60 + 160),
             strategy: [
               %{
                 date: ~D[2020-01-01],
                 action: :buy
               },
               %{
                 date: ~D[2020-01-02],
                 action: :sell
               },
               %{
                 date: ~D[2020-01-04],
                 action: :buy
               },
               %{
                 date: ~D[2020-01-06],
                 action: :sell
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
