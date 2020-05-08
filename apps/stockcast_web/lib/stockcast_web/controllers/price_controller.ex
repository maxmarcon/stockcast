defmodule StockcastWeb.PriceController do
  use StockcastWeb, :controller

  alias Stockcast.Prices

  action_fallback StockcastWeb.FallbackController

  def retrieve(conn, %{"symbol" => symbol, "from" => from, "to" => to}) do
    with {:ok, from_date} <- Date.from_iso8601(from),
         {:ok, to_date} <- Date.from_iso8601(to) do
      retrieve_prices_and_send_response(conn, symbol, from_date, to_date)
    else
      _ -> {:error, :bad_request}
    end
  end

  def retrieve(conn, %{"symbol" => symbol, "from" => from}) do
    case Date.from_iso8601(from) do
      {:ok, from_date} ->
        retrieve_prices_and_send_response(conn, symbol, from_date, Date.add(Date.utc_today(), -1))

      _ ->
        {:error, :bad_request}
    end
  end

  defp retrieve_prices_and_send_response(conn, symbol, from_date, to_date) do
    case Prices.retrieve(symbol, from_date, to_date) do
      {:ok, prices} -> render(conn, :index, %{prices: prices})
      {:error, :invalid_dates} -> {:error, :bad_request}
      {:error, :too_old} -> {:error, :gone}
      _ -> {:error, :internal_server_error}
    end
  end
end
