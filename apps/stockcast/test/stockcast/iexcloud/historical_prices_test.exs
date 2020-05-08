defmodule Stockcast.IexCloud.HistoricalPricesTest do
  use Stockcast.DataCase

  import Mock
  import Stockcast.TestUtils

  alias Stockcast.IexCloud.HistoricalPrices, as: Prices

  @symbol "00XP-GY"
  @date_from ~D[2020-04-02]
  @date_to ~D[2020-04-15]
  @today ~D[2020-04-16]
  @far_future ~D[2025-04-16]

  defp reset_cache() do
    {:ok, true} = Cachex.reset(:iex_cloud)
  end

  describe "with invalid dates" do
    test "retrieve/3 returns an error (wrong order)" do
      {:error, :invalid_dates} = Prices.retrieve(@symbol, @date_to, @date_from)
    end

    test "retrieve/3 returns an error (today prices)" do
      {:error, :invalid_dates} = Prices.retrieve(@symbol, @date_to, Date.utc_today())
    end

    test "retrieve/3 returns an error (future prices)" do
      {:error, :invalid_dates} = Prices.retrieve(@symbol, @date_to, Date.add(Date.utc_today(), 1))
    end
  end

  describe "when at least @data_fraction_thr prices are available locally" do
    setup do
      prices = store_prices()
      [prices: prices]
    end

    test "retrieve/3 returns them", %{prices: prices} do
      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @date_from, @date_to)

      assert retrieved_prices == prices
    end
  end

  describe "when less than @data_fraction_thr prices are available locally" do
    setup do
      prices = store_prices()
      delete_some_prices()
      mock_price_api()
      reset_cache()

      [prices: prices]
    end

    setup_with_mocks([{Date, [:passthrough], utc_today: fn -> @today end}]) do
      :ok
    end

    test "retrieve/3 fetches via the API and returns them", %{prices: prices} do
      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @date_from, @date_to)

      assert retrieved_prices |> Enum.map(&Map.drop(&1, [:id, :updated_at, :inserted_at])) ==
               prices |> Enum.map(&Map.drop(&1, [:id, :updated_at, :inserted_at]))
    end

    test "retrieve/3 returns an error with changeset if some data can't be stored" do
      mock_price_api(:missing_date)

      assert {:error, %Ecto.Changeset{errors: [date: {_, [{:validation, :required}]}]}} =
               Prices.retrieve(@symbol, @date_from, @date_to)
    end

    test_with_mock "retrieve/3 returns an error if the data to be fetched is too far back in time",
                   Date,
                   [:passthrough],
                   utc_today: fn -> @far_future end do
      assert {:error, :too_old} == Prices.retrieve(@symbol, @date_from, @date_to)
    end

    test "retrieve/3 does not attempt to fetch the data from the API again if it was done recently" do
      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @date_from, @date_to)
      assert length(retrieved_prices) == 10

      delete_some_prices()
      Tesla.Mock.mock(fn _ -> raise "should not be called" end)

      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @date_from, @date_to)
      assert length(retrieved_prices) == 8
    end

    test "retrieve/3 fetches the data from the API again if enough time has elapsed since the last call" do
      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @date_from, @date_to)
      assert length(retrieved_prices) == 10

      delete_some_prices()
      reset_cache()

      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @date_from, @date_to)
      assert length(retrieved_prices) == 10
    end
  end
end
