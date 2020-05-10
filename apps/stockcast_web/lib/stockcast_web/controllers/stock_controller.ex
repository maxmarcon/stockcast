defmodule StockcastWeb.StockController do
  use StockcastWeb, :controller

  alias Stockcast.Stocks

  action_fallback StockcastWeb.FallbackController

  def show(conn, %{"id" => id}) do
    stock = Stocks.get!(id)

    render(conn, :show, %{stock: stock})
  end

  def search(conn, %{"q" => term, "limit" => limit}) do
    case Integer.parse(limit) do
      {limit, _} ->
        render(conn, :index, %{stocks: Stocks.search(term, limit)})

      :error ->
        {:error, :bad_request, "Limit must be an integer"}
    end
  end

  def search(conn, %{"q" => term}) do
    stocks = Stocks.search(term)

    render(conn, :index, %{stocks: stocks})
  end
end
