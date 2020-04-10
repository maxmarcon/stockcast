defmodule StockcastWeb.Router do
  use StockcastWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", StockcastWeb do
    pipe_through :api
  end
end
