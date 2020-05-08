defmodule Stockcast.PricesTest do
  use Stockcast.DataCase

  import Mock

  alias Stockcast.Prices
  alias Stockcast.Repo
  alias Stockcast.IexCloud.HistoricalPrice, as: Price

  @symbol "00XP-GY"
  @data_from ~D[2020-04-02]
  @data_to ~D[2020-04-15]

  defp store_prices() do
    api_prices = Jason.decode!(File.read!("#{__DIR__}/iexcloud/api_prices.json"))

    api_prices
    |> Enum.map(&Repo.insert!(Price.changeset(Map.put_new(&1, "symbol", @symbol))))
    |> Enum.sort_by(& &1.date)
  end

  setup do
    prices = store_prices()
    [prices: prices]
  end

  test "retrieve/3 returns prices", %{prices: prices} do
    {:ok, retrieved_prices} = Prices.retrieve(@symbol, @data_from, @data_to)

    assert retrieved_prices == prices
  end

  describe "when to date is omitted" do
    test_with_mock "retrieve/3 uses yesterday", %{prices: prices}, Date, [:passthrough],
      utc_today: fn -> ~D[2020-04-16] end do
      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @data_from)

      assert retrieved_prices == prices
    end
  end
end
