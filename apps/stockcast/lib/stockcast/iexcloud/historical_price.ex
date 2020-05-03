defmodule Stockcast.IexCloud.HistoricalPrice do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  @derive {Jason.Encoder, except: [:__meta__, :inserted_at, :updated_at, :id]}

  schema "iexc_historical_prices" do
    field :symbol, :string
    field :date, :date
    field :open, :decimal
    field :high, :decimal
    field :low, :decimal
    field :close, :decimal
    field :volume, :decimal
    field :uOpen, :decimal
    field :uHigh, :decimal
    field :uLow, :decimal
    field :uClose, :decimal
    field :uVolume, :decimal
    field :change, :decimal
    field :changePercent, :decimal
    field :label, :string
    field :changeOverTime, :decimal

    timestamps(type: :utc_datetime)
  end

  def changeset(hprice \\ %HistoricalPrice{}, params) do
    hprice
    |> cast(params, [
      :symbol,
      :date,
      :open,
      :high,
      :low,
      :close,
      :volume,
      :uOpen,
      :uHigh,
      :uLow,
      :uClose,
      :uVolume,
      :change,
      :changePercent,
      :label,
      :changeOverTime
    ])
    |> validate_required([:symbol, :date])
    |> unique_constraint(:symbol, name: :iexc_historical_prices_symbol_date_index)
  end
end
