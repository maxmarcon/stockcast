defmodule Stockcast.IexCloud.HistoricalPricesTest do
  use Stockcast.DataCase

  alias Stockcast.IexCloud.HistoricalPrices, as: Prices
  alias Stockcast.IexCloud.HistoricalPrice, as: Price
  alias Stockcast.Repo

  @symbol "00XP-GY"
  @data_from ~D[2020-04-02]
  @data_to ~D[2020-04-15]

  defp store_prices(how_many) do
    api_prices = Jason.decode!(File.read!("#{__DIR__}/api_prices.json"))

    api_prices
    |> Enum.take(how_many)
    |> Enum.map(&Repo.insert!(Price.changeset(Map.put_new(&1, "symbol", @symbol))))
    |> Enum.sort_by(& &1.date)
  end

  defp store_prices, do: store_prices(10)

  defp mock_api() do
    api_prices = Jason.decode!(File.read!("#{__DIR__}/api_prices.json"))

    Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: api_prices, status: 200} end)
  end

  defp mock_api(:missing_field) do
    api_prices =
      Jason.decode!(File.read!("#{__DIR__}/api_prices.json"))
      |> Enum.map(&Map.delete(&1, "date"))

    Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: api_prices, status: 200} end)
  end

  describe "with invalid dates" do
    test "retrieve/3 returns an error (wrong order)" do
      {:error, :invalid_dates} = Prices.retrieve(@symbol, @data_to, @data_from)
    end

    test "retrieve/3 returns an error (future dates)" do
      {:error, :invalid_dates} = Prices.retrieve(@symbol, @data_to, Date.add(Date.utc_today(), 1))
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
      {2, _} = Repo.delete_all(from p in Price, where: p.date >= ^~D[2020-04-14])
      mock_api()

      [prices: prices]
    end

    test "retrieve/3 fetches and returns them", %{prices: prices} do
      {:ok, retrieved_prices} = Prices.retrieve(@symbol, @data_from, @data_to)

      assert retrieved_prices |> Enum.map(&Map.delete(&1, :id)) ==
               prices |> Enum.map(&Map.delete(&1, :id))
    end

    test "retrieve/3 returns an error with changeset if some data can't be stored" do
      mock_api(:missing_field)

      assert {:error, %Ecto.Changeset{errors: [date: {_, [{:validation, :required}]}]}} =
               Prices.retrieve(@symbol, @data_from, @data_to)
    end
  end
end
