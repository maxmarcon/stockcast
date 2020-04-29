defmodule StockcastWeb.Router do
  use StockcastWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/v1", StockcastWeb do
    pipe_through :api

    get("/stocks/search", StockController, :search)
    get("/stocks/:id", StockController, :show)
  end
end
