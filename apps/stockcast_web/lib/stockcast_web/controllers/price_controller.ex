defmodule StockcastWeb.PriceController do
  use StockcastWeb, :controller

  require Logger

  alias Stockcast.Prices

  @invalid_date_format "Invalid date format"

  action_fallback StockcastWeb.FallbackController

  def index(conn, %{"symbol" => symbol, "from" => from, "to" => to}) do
    with {:ok, from_date} <- Date.from_iso8601(from),
         {:ok, to_date} <- Date.from_iso8601(to) do
      retrieve_prices_and_send_response(conn, symbol, from_date, to_date)
    else
      _ -> {:error, :bad_request, @invalid_date_format}
    end
  end

  def index(conn, %{"symbol" => symbol, "from" => from}) do
    case Date.from_iso8601(from) do
      {:ok, from_date} ->
        retrieve_prices_and_send_response(conn, symbol, from_date, Date.add(Date.utc_today(), -1))

      _ ->
        {:error, :bad_request, @invalid_date_format}
    end
  end

  defp retrieve_prices_and_send_response(conn, symbol, from_date, to_date) do
    case Prices.retrieve(symbol, from_date, to_date) do
      {:ok, prices} ->
        render(conn, :index, %{prices: prices})

      {:error, :invalid_dates} ->
        {:error, :bad_request, :invalid_dates}

      {:error, :too_old} ->
        {:error, :gone, :too_old}

      {:error, :fetched_recently} ->
        {:error, :too_many_requests, :fetched_recently}

      {:error, error} ->
        Logger.error(inspect(error))
        {:error, :internal_server_error}

      _ ->
        {:error, :internal_server_error}
    end
  end
end
