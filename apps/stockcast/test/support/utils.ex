defmodule Stockcast.TestUtils do
  import Ecto.Query

  alias Stockcast.Repo
  alias Stockcast.IexCloud.HistoricalPrice, as: Price

  @symbol "00XP-GY"

  def store_prices(how_many \\ 10) do
    Jason.decode!(File.read!("#{__DIR__}/../stockcast/iexcloud/api_prices.json"))
    |> Enum.take(how_many)
    |> Enum.map(&Repo.insert!(Price.changeset(Map.put_new(&1, "symbol", @symbol))))
    |> Enum.sort_by(& &1.date)
  end

  def delete_some_prices() do
    {2, _} = Repo.delete_all(from p in Price, where: p.date >= ^~D[2020-04-14])
  end

  def mock_price_api() do
    api_prices = Jason.decode!(File.read!("#{__DIR__}/../stockcast/iexcloud/api_prices.json"))

    Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: api_prices, status: 200} end)
  end

  def mock_price_api(:missing_date) do
    api_prices =
      Jason.decode!(File.read!("#{__DIR__}/../stockcast/iexcloud/api_prices.json"))
      |> Enum.map(&Map.delete(&1, "date"))

    Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: api_prices, status: 200} end)
  end

  def mock_price_api(:not_found) do
    Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: "Unknown symbol", status: 404} end)
  end

  def mock_isin_api() do
    api_isins = Jason.decode!(File.read!("#{__DIR__}/../stockcast/iexcloud/api_isins.json"))

    Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: api_isins, status: 200} end)
  end

  def mock_symbols_api() do
    api_symbols = Jason.decode!(File.read!("#{__DIR__}/../stockcast/iexcloud/api_symbols.json"))

    Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: api_symbols, status: 200} end)

    api_symbols
  end

  def reset_cache() do
    {:ok, true} = Cachex.reset(:iex_cloud)
  end
end
