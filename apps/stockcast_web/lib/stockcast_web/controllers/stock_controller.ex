defmodule StockcastWeb.StockController do
  use StockcastWeb, :controller

  alias Stockcast.Stocks

  action_fallback StockcastWeb.FallbackController

  def show(conn, %{"id" => id}) do
    stock = Stocks.get!(id)

    render(conn, :show, %{stock: stock})
  end
end
