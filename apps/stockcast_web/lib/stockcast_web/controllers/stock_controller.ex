defmodule StockcastWeb.StockController do
  use StockcastWeb, :controller

  alias Stockcast.Stocks

  action_fallback StockcastWeb.FallbackController

  def show(conn, %{"id" => id}) do
    stock = Stocks.get!(id)

    render(conn, :show, %{stock: stock})
  end

  def search(conn, %{"q" => term, "limit" => limit}) do
    stocks = Stocks.search(term, limit)

    render(conn, :index, %{stocks: stocks})
  end

  def search(conn, %{"q" => term}) do
    stocks = Stocks.search(term)

    render(conn, :index, %{stocks: stocks})
  end
end
