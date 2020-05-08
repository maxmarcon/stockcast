defmodule StockcastWeb.PriceView do
  use StockcastWeb, :view
  alias StockcastWeb.PriceView

  def render("index.json", %{prices: prices}) do
    %{data: render_many(prices, PriceView, "price.json")}
  end

  def render("show.json", %{price: price}) do
    %{data: render_one(price, PriceView, "price.json")}
  end

  def render("price.json", %{price: price}) do
    price
  end
end
