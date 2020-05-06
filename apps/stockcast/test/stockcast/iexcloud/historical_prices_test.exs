defmodule Stockcast.IexCloud.HistoricalPricesTest do
  use Stockcast.DataCase

  import Mock

  alias Stockcast.IexCloud.HistoricalPrices, as: Prices
  alias Stockcast.IexCloud.HistoricalPrice, as: Price
  alias Stockcast.Repo

  @symbol "00XP-GY"
  @data_from ~D[2020-04-02]
  @data_to ~D[2020-04-15]
  @tomorrow Date.add(Date.utc_today(), 1)
  @today Date.utc_today()
  @far_future ~D[2025-04-16]

  defp store_prices(how_many) do
    api_prices = Jason.decode!(File.read!("#{__DIR__}/api_prices.json"))

    api_prices
    |> Enum.take(how_many)
    |> Enum.map(&Repo.insert!(Price.changeset(Map.put_new(&1, "symbol", @symbol))))
    |> Enum.sort_by(& &1.date)
  end

  defp store_prices, do: store_prices(10)

  defp delete_some_prices() do
    {2, _} = Repo.delete_all(from p in Price, where: p.date >= ^~D[2020-04-14])
  end

  defp mock_api() do
    api_prices = Jason.decode!(File.read!("#{__DIR__}/api_prices.json"))

    Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: api_prices, status: 200} end)
  end

  defp mock_api(:missing_date) do
    api_prices =
      Jason.decode!(File.read!("#{__DIR__}/api_prices.json"))
      |> Enum.map(&Map.delete(&1, "date"))

    Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: api_prices, status: 200} end)
  end

  defp reset_cache() do
    {:ok, true} = Cachex.reset(:iex_cloud)
  end

  describe "with invalid dates" do
    test "retrieve/3 returns an error (wrong order)" do
      {:error, :invalid_dates} = Prices.retrieve(@symbol, @data_to, @data_from)
    end

    test "retrieve/3 returns an error (today prices)" do
      {:error, :invalid_dates} = Prices.retrieve(@symbol, @data_to, @today)
    end

    test "retrieve/3 returns an error (future prices)" do
      {:error, :invalid_dates} = Prices.retrieve(@symbol, @data_to, @tomorrow)
    end
  end

  describe "when at least @data_fraction_thr prices are available locally" do
    setup do
      prices = store_prices()
      [prices: prices]
    end

    test "retrieve/3 returns them", %{prices: prices} do
      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @data_from, @data_to)

      assert retrieved_prices == prices
    end
  end

  describe "when less than @data_fraction_thr prices are available locally" do
    setup do
      prices = store_prices()
      delete_some_prices()
      mock_api()
      reset_cache()

      [prices: prices]
    end

    setup_with_mocks([{Date, [:passthrough], utc_today: fn -> @today end}]) do
      :ok
    end

    test "retrieve/3 fetches via the API and returns them", %{prices: prices} do
      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @data_from, @data_to)

      assert retrieved_prices |> Enum.map(&Map.drop(&1, [:id, :updated_at, :inserted_at])) ==
               prices |> Enum.map(&Map.drop(&1, [:id, :updated_at, :inserted_at]))
    end

    test "retrieve/3 returns an error with changeset if some data can't be stored" do
      mock_api(:missing_date)

      assert {:error, %Ecto.Changeset{errors: [date: {_, [{:validation, :required}]}]}} =
               Prices.retrieve(@symbol, @data_from, @data_to)
    end

    test "retrieve/3 returns an error if the data to be fetched is too far back in time" do
      with_mock Date, [:passthrough], utc_today: fn -> @far_future end do
        assert {:error, :too_old} == Prices.retrieve(@symbol, @data_from, @data_to)
      end
    end

    test "retrieve/3 does not attempt to fetch the data from the API again if it was done recently" do
      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @data_from, @data_to)
      assert length(retrieved_prices) == 10

      delete_some_prices()
      Tesla.Mock.mock(fn _ -> raise "should not be called" end)

      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @data_from, @data_to)
      assert length(retrieved_prices) == 8
    end

    test "retrieve/3 fetches the data from the API again if enough time has elapsed since the last call" do
      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @data_from, @data_to)
      assert length(retrieved_prices) == 10

      delete_some_prices()
      reset_cache()

      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @data_from, @data_to)
      assert length(retrieved_prices) == 10
    end
  end
end
