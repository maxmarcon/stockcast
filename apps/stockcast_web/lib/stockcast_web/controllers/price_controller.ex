defmodule StockcastWeb.PriceController do
  use StockcastWeb, :controller

  require Logger

  alias Stockcast.Prices
  alias Stockcast.Performance

  @invalid_date_format "Invalid date format"
  @invalid_sampling "Sampling must be an integer >= 1"

  action_fallback StockcastWeb.FallbackController

  def index(conn, %{"symbol" => symbol, "from" => from, "to" => to, "sampling" => sampling}) do
    with {:ok, from_date} <- Date.from_iso8601(from),
         {:ok, to_date} <- Date.from_iso8601(to),
         {:ok, sampling} <- parse_sampling(sampling) do
      retrieve_prices_and_send_response(conn, symbol, from_date, to_date, sampling)
    else
      :error -> {:error, :bad_request, @invalid_sampling}
      {:error, :invalid_format} -> {:error, :bad_request, @invalid_date_format}
      _ -> {:error, :bad_request}
    end
  end

  def index(conn, %{"symbol" => symbol, "from" => from, "to" => to}) do
    with {:ok, from_date} <- Date.from_iso8601(from),
         {:ok, to_date} <- Date.from_iso8601(to) do
      retrieve_prices_and_send_response(conn, symbol, from_date, to_date)
    else
      {:error, :invalid_format} -> {:error, :bad_request, @invalid_date_format}
      _ -> {:error, :bad_request}
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

  defp parse_sampling(sampling) do
    case Integer.parse(sampling) do
      {sampling, _} when sampling >= 1 -> {:ok, sampling}
      _ -> :error
    end
  end

  defp retrieve_prices_and_send_response(conn, symbol, from_date, to_date, sampling \\ 1) do
    case Prices.retrieve(symbol, from_date, to_date, sampling) do
      {:ok, prices} ->
        render(conn, :index, %{
          prices: prices,
          performance: Prices.trade_from_historical_prices(prices) |> Performance.relative()
        })

      {:error, :invalid_dates} ->
        {:error, :bad_request, :invalid_dates}

      {:error, :too_old} ->
        {:error, :gone, :too_old}

      {:error, :unknown_symbol} ->
        {:error, :not_found, :unknown_symbol}

      {:error, error} ->
        Logger.error(inspect(error))
        {:error, :internal_server_error}

      _ ->
        {:error, :internal_server_error}
    end
  end
end
