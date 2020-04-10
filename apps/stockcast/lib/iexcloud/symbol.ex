defmodule Stockcast.IexCloud.Symbol do
  use Ecto.Schema

  schema "symbols" do
    field :symbol, :string
    field :exchange, :string
    field :name, :string
    field :date, :date
    field :type, :string
    field :iex_id, :string
    field :region, :string
    field :currency, :string
    field :figi, :string
    field :cik, :string
  end
end
