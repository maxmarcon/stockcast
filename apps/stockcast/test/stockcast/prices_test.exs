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

  test "retrieve/3 returns prices", %{prices: prices} do
    {:ok, retrieved_prices} = Prices.retrieve(@symbol, @date_from, @date_to)

    assert retrieved_prices == prices
  end

  describe "when to date is omitted" do
    test_with_mock "retrieve/3 uses yesterday", %{prices: prices}, Date, [:passthrough],
      utc_today: fn -> ~D[2020-04-16] end do
      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @date_from)

      assert retrieved_prices == prices
    end
  end
end
