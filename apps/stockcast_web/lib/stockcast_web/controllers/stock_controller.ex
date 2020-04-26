defmodule StockcastWeb.StockController do
  use StockcastWeb, :controller

  alias Stockcast.Search
  alias Stockcast.Search.Stock

  action_fallback StockcastWeb.FallbackController
  #
  #  def index(conn, _params) do
  #    stocks = Search.list_stocks()
  #    render(conn, "index.json", stocks: stocks)
  #  end
  #
  #  def create(conn, %{"stock" => stock_params}) do
  #    with {:ok, %Stock{} = stock} <- Search.create_stock(stock_params) do
  #      conn
  #      |> put_status(:created)
  #      |> put_resp_header("location", Routes.stock_path(conn, :show, stock))
  #      |> render("show.json", stock: stock)
  #    end
  #  end
  #
  #  def show(conn, %{"id" => id}) do
  #    stock = Search.get_stock!(id)
  #    render(conn, "show.json", stock: stock)
  #  end
  #
  #  def update(conn, %{"id" => id, "stock" => stock_params}) do
  #    stock = Search.get_stock!(id)
  #
  #    with {:ok, %Stock{} = stock} <- Search.update_stock(stock, stock_params) do
  #      render(conn, "show.json", stock: stock)
  #    end
  #  end
  #
  #  def delete(conn, %{"id" => id}) do
  #    stock = Search.get_stock!(id)
  #
  #    with {:ok, %Stock{}} <- Search.delete_stock(stock) do
  #      send_resp(conn, :no_content, "")
  #    end
  #  end
end
