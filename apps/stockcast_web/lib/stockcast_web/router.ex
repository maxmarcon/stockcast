defmodule StockcastWeb.Router do
  use StockcastWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:put_secure_browser_headers)
  end

  scope "/v1", StockcastWeb do
    pipe_through :api

    get("/stocks/search", StockController, :search)
    get("/stocks/:id", StockController, :show)
    get("/stocks/symbol/:symbol", StockController, :show_by_symbol)
    get("/prices/:symbol/from/:from/to/:to", PriceController, :index)
    get("/prices/:symbol/from/:from", PriceController, :index)
  end

  scope "/", StockcastWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/*path", PageController, :app)
  end
end
