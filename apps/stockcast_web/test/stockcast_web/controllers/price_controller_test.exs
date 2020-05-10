defmodule StockcastWeb.PriceControllerTest do
  use StockcastWeb.ConnCase

  import Stockcast.TestUtils
  import StockcastWeb.TestUtils
  import Mock

  @symbol "00XP-GY"
  @date_from "2020-04-02"
  @date_to "2020-04-15"
  @today ~D[2020-04-16]
  @far_future "2025-04-16"

  setup do
    store_prices()
    reset_cache()

    :ok
  end

  setup_with_mocks([{Date, [:passthrough], utc_today: fn -> @today end}]) do
    :ok
  end

  test "can retrieve prices", %{conn: conn} do
    conn = get(conn, Routes.price_path(conn, :index, @symbol, @date_from, @date_to))

    json_data = json_response(conn, 200)["data"]

    assert_json_data(json_data)
  end

  test "can retrieve prices if to date is omitted", %{conn: conn} do
    conn = get(conn, Routes.price_path(conn, :index, @symbol, @date_from))

    json_data = json_response(conn, 200)["data"]

    assert_json_data(json_data)
  end

  test "returns 400 if from date is invalid", %{conn: conn} do
    conn = get(conn, Routes.price_path(conn, :index, @symbol, "invalid date", @date_to))

    json_error_response(conn, 400, "Invalid date format")
  end

  test "returns 400 if to date is invalid", %{conn: conn} do
    conn = get(conn, Routes.price_path(conn, :index, @symbol, @date_from, "invalid date"))

    json_error_response(conn, 400, "Invalid date format")
  end

  test "returns 400 if asked for future prices", %{conn: conn} do
    conn =
      get(
        conn,
        Routes.price_path(
          conn,
          :index,
          @symbol,
          @date_from,
          Date.to_iso8601(Date.add(Date.utc_today(), 1))
        )
      )

    json_error_response(conn, 400, "Invalid dates")
  end

  test "returns 400 if asked for today prices", %{conn: conn} do
    conn =
      get(
        conn,
        Routes.price_path(conn, :index, @symbol, @date_from, Date.to_iso8601(Date.utc_today()))
      )

    json_error_response(conn, 400, "Invalid dates")
  end

  test "returns 400 if order of dates is wrong", %{conn: conn} do
    conn = get(conn, Routes.price_path(conn, :index, @symbol, @date_to, @date_from))

    json_error_response(conn, 400, "Invalid dates")
  end

  describe "when prices need to be fetched from the API" do
    setup do
      delete_some_prices()
      mock_price_api()

      :ok
    end

    test_with_mock "returns 410 if the data to be fetched is too far back in time",
                   %{conn: conn},
                   Date,
                   [:passthrough],
                   utc_today: fn -> Date.from_iso8601!(@far_future) end do
      conn = get(conn, Routes.price_path(conn, :index, @symbol, @date_from, @date_to))

      json_error_response(conn, 410, "Too old")
    end

    test "returns 500 if some prices cannot be stored", %{conn: conn} do
      mock_price_api(:missing_date)

      conn = get(conn, Routes.price_path(conn, :index, @symbol, @date_from, @date_to))

      json_response(conn, 500)
    end

    test "returns 429 if prices have been fetched recently", %{conn: conn} do
      conn = get(conn, Routes.price_path(conn, :index, @symbol, @date_from, @date_to))

      json_response(conn, 200)

      delete_some_prices()

      conn = get(conn, Routes.price_path(conn, :index, @symbol, @date_from, @date_to))

      json_error_response(conn, 429, "Fetched recently")
    end

    test "returns 404 if symbol can't be found", %{conn: conn} do
      mock_price_api(:not_found)

      conn = get(conn, Routes.price_path(conn, :index, @symbol, @date_from, @date_to))

      json_error_response(conn, 404, "Unknown symbol")
    end
  end

  defp assert_json_data(data) do
    assert length(data) == 10

    data
    |> Enum.with_index()
    |> Enum.each(fn {price, index} ->
      assert price["symbol"] == @symbol

      [
        "date",
        "open",
        "close",
        "high",
        "low",
        "volume",
        "uOpen",
        "uClose",
        "uHigh",
        "uLow",
        "uVolume",
        "change",
        "changePercent",
        "label",
        "changeOverTime"
      ]
      |> Enum.each(
        &assert Map.has_key?(price, &1), "price at position #{index} is missing key \"#{&1}\""
      )
    end)
  end
end
