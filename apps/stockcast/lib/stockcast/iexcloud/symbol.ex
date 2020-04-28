defmodule Stockcast.IexCloud.Symbol do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__
  alias Stockcast.IexCloud.Isin

  @derive {Jason.Encoder, except: [:__meta__, :isin]}

  schema "iexc_symbols" do
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

    has_many :isin, Isin, foreign_key: :iex_id, references: :iex_id
    timestamps(type: :utc_datetime)
  end

  def changeset(symbol \\ %Symbol{}, params) do
    symbol
    |> cast(params, [
      :symbol,
      :exchange,
      :name,
      :date,
      :type,
      :iex_id,
      :region,
      :currency,
      :figi,
      :cik
    ])
    |> validate_required([:symbol, :name, :date, :iex_id, :region, :currency])
    |> validate_length(:currency, is: 3)
    |> validate_length(:region, is: 2)
    |> unique_constraint(:iex_id)
  end
end
