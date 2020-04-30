defmodule Stockcast.StocksTest do
  use Stockcast.DataCase

  alias Stockcast.Stocks
  alias Stockcast.Repo
  alias Stockcast.IexCloud.Symbol, as: IexSymbol
  alias Stockcast.IexCloud.Isin

  @iex_symbols [
    %{
      symbol: "00XP-GY",
      exchange: "RET",
      name: "RaagmrW us EGoeteadirCr lDtmrie e dadel(eHU- nT saGy.) N",
      date: "2020-04-26",
      type: "et",
      iex_id: "IEX_5339503747312D52",
      region: "DE",
      currency: "EUR",
      figi: "Q5BBS02RZ0G4",
      cik: nil
    },
    %{
      symbol: "00XR-GY",
      exchange: "TRE",
      name: " elmldRe(mSeEyrsgirv aDeGienrte.Ur - ad)  WHediC To",
      date: "2020-04-26",
      type: "et",
      iex_id: "IEX_4E53503759592D52",
      region: "DE",
      currency: "EUR",
      figi: "70GBB60WQ0R2",
      cik: nil
    },
    %{
      symbol: "00XS-GY",
      exchange: "RTE",
      name: "d)ReErsdemdmyieheagtaon rreD l( tHeeU  WC. iaGT- W",
      date: "2020-04-26",
      type: "et",
      iex_id: "IEX_5043564631472D52",
      region: "DE",
      currency: "EUR",
      figi: "BR980G60V2BQ",
      cik: nil
    }
  ]

  @isin %{
    isin: "IE00B4L5Y983",
    iex_id: "IEX_5043564631472D52"
  }

  setup do
    Enum.each(@iex_symbols, fn iex_symbol ->
      Repo.insert!(IexSymbol.changeset(iex_symbol))
    end)

    Repo.insert!(Isin.changeset(@isin))

    setup_isins_api_mock()

    [iex_symbols: Repo.all(IexSymbol)]
  end

  defp setup_isins_api_mock do
    api_isins = [
      %{
        "symbol" => "IRRRF",
        "region" => "US",
        "exchange" => "CTO",
        "iexId" => "IEX_5339503747312D52"
      }
    ]

    Tesla.Mock.mock(fn %{method: :get, query: [isin: "DE00B4L5Y984", token: "fake_token"]} ->
      %Tesla.Env{body: api_isins, status: 200}
    end)
  end

  describe "search/2" do
    test "can find stocks by symbol", %{iex_symbols: iex_symbols} do
      symbol = Enum.at(iex_symbols, 1)

      assert Stocks.search("00XR-GY") == [symbol]
    end

    test "can find stocks by symbol prefix", %{iex_symbols: iex_symbols} do
      assert Stocks.search("00x") == iex_symbols
    end

    test "can find stocks by name", %{iex_symbols: iex_symbols} do
      symbol = Enum.at(iex_symbols, 1)

      assert Stocks.search("Gienrte") == [symbol]
    end

    test "can find stocks by isin", %{iex_symbols: iex_symbols} do
      symbol = Enum.at(iex_symbols, 2)

      assert Stocks.search("Ie00B4L5Y983") == [symbol]
    end

    test "can find stocks by isin prefix", %{iex_symbols: iex_symbols} do
      symbol = Enum.at(iex_symbols, 2)

      assert Stocks.search("Ie00") == [symbol]
    end

    test "can find stocks by multiple search terms separated by spaces", %{
      iex_symbols: iex_symbols
    } do
      [_ | symbols] = iex_symbols

      assert Stocks.search("wh   wc") == symbols
    end

    test "triggers isin search if isin is not present", %{iex_symbols: iex_symbols} do
      symbol = Enum.at(iex_symbols, 0)

      assert Stocks.search("De00B4L5Y984") == [symbol]
    end
  end

  describe "get/1" do
    test "find stocks by ID", %{iex_symbols: iex_symbols} do
      symbol = Enum.at(iex_symbols, 1)

      assert Stocks.get("IEX_4E53503759592D52") == symbol
    end

    test "returns nil if none is found" do
      assert is_nil(Stocks.get("DOESNOTEXIST"))
    end
  end

  describe "get!/1" do
    test "find stocks by ID", %{iex_symbols: iex_symbols} do
      symbol = Enum.at(iex_symbols, 1)

      assert Stocks.get("IEX_4E53503759592D52") == symbol
    end

    test "throws if none is found" do
      assert_raise Ecto.NoResultsError, fn ->
        Stocks.get!("DOESNOTEXIST")
      end
    end
  end
end
