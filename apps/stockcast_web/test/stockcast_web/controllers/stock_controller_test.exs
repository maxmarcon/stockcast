defmodule StockcastWeb.StockControllerTest do
  use StockcastWeb.ConnCase

  alias Stockcast.Repo
  alias Stockcast.IexCloud.Symbol, as: IexSymbol

  import StockcastWeb.TestUtils

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

  setup do
    Enum.each(@iex_symbols, fn iex_symbol ->
      Repo.insert!(IexSymbol.changeset(iex_symbol))
    end)

    :ok
  end

  test "can retrieve a stock", %{conn: conn} do
    conn = get(conn, Routes.stock_path(conn, :show, "IEX_5339503747312D52"))

    assert json_response(conn, 200)["data"] == %{
             "iex_id" => "IEX_5339503747312D52",
             "exchange" => "RET",
             "name" => "RaagmrW us EGoeteadirCr lDtmrie e dadel(eHU- nT saGy.) N",
             "date" => "2020-04-26",
             "type" => "et",
             "region" => "DE",
             "currency" => "EUR",
             "symbol" => "00XP-GY",
             "figi" => "Q5BBS02RZ0G4",
             "cik" => nil
           }
  end

  test "returns 404 if a stock can't be retrieved", %{conn: conn} do
    assert_error_sent(404, fn ->
      get(conn, Routes.stock_path(conn, :show, "DONTEXIST"))
    end)
  end

  test "can search for stocks", %{conn: conn} do
    conn = get(conn, Routes.stock_path(conn, :search, q: "ad"))

    assert json_response(conn, 200)["data"] == [
             %{
               "symbol" => "00XP-GY",
               "exchange" => "RET",
               "name" => "RaagmrW us EGoeteadirCr lDtmrie e dadel(eHU- nT saGy.) N",
               "date" => "2020-04-26",
               "type" => "et",
               "iex_id" => "IEX_5339503747312D52",
               "region" => "DE",
               "currency" => "EUR",
               "figi" => "Q5BBS02RZ0G4",
               "cik" => nil
             },
             %{
               "symbol" => "00XR-GY",
               "exchange" => "TRE",
               "name" => " elmldRe(mSeEyrsgirv aDeGienrte.Ur - ad)  WHediC To",
               "date" => "2020-04-26",
               "type" => "et",
               "iex_id" => "IEX_4E53503759592D52",
               "region" => "DE",
               "currency" => "EUR",
               "figi" => "70GBB60WQ0R2",
               "cik" => nil
             }
           ]
  end

  test "can search for stocks and limit result set", %{conn: conn} do
    conn = get(conn, Routes.stock_path(conn, :search, q: "ad", limit: 1))

    assert json_response(conn, 200)["data"] == [
             %{
               "symbol" => "00XP-GY",
               "exchange" => "RET",
               "name" => "RaagmrW us EGoeteadirCr lDtmrie e dadel(eHU- nT saGy.) N",
               "date" => "2020-04-26",
               "type" => "et",
               "iex_id" => "IEX_5339503747312D52",
               "region" => "DE",
               "currency" => "EUR",
               "figi" => "Q5BBS02RZ0G4",
               "cik" => nil
             }
           ]
  end

  test "returns 400 if search parameters are missing", %{conn: conn} do
    assert_error_sent(400, fn -> get(conn, Routes.stock_path(conn, :search)) end)
  end

  test "returns 400 if some search parameters have wrong format", %{conn: conn} do
    conn = get(conn, Routes.stock_path(conn, :search, q: "X", limit: "not a number"))

    json_error_response(conn, 400, "Limit must be an integer")
  end
end
