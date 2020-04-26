defmodule Stockcast.SearchTest do
  use Stockcast.DataCase

  alias Stockcast.Search
  alias Stockcast.Repo
  alias Stockcast.IexCloud.Symbol
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
      Repo.insert!(Symbol.changeset(iex_symbol))
    end)

    Repo.insert!(Isin.changeset(@isin))

    setup_isins_api_mock()

    [iex_symbols: Repo.all(Symbol)]
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

  describe "search/1" do
    test "can find stocks by symbol", %{iex_symbols: iex_symbols} do
      symbol = Enum.at(iex_symbols, 1)

      assert Search.search("00XR-GY") == [symbol]
    end

    test "can find stocks by symbol prefix", %{iex_symbols: iex_symbols} do
      assert Search.search("00x") == iex_symbols
    end

    test "can find stocks by name", %{iex_symbols: iex_symbols} do
      symbol = Enum.at(iex_symbols, 1)

      assert Search.search("Gienrte") == [symbol]
    end

    test "can find stocks by isin", %{iex_symbols: iex_symbols} do
      symbol = Enum.at(iex_symbols, 2)

      assert Search.search("Ie00B4L5Y983") == [symbol]
    end

    test "can find stocks by isin prefix", %{iex_symbols: iex_symbols} do
      symbol = Enum.at(iex_symbols, 2)

      assert Search.search("Ie00") == [symbol]
    end

    test "triggers isin search if isin is not present", %{iex_symbols: iex_symbols} do
      symbol = Enum.at(iex_symbols, 0)

      Search.search("De00B4L5Y984") == [symbol]
    end
  end
end
