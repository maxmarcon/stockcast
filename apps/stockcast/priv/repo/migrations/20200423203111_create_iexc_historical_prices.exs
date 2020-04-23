defmodule Stockcast.Repo.Migrations.CreateIexcHistoricalPrices do
  use Ecto.Migration

  def change do
    create table("iexc_historical_prices") do
      add :symbol, :string, null: false
      add :date, :date, null: false
      add :open, :decimal
      add :high, :decimal
      add :low, :decimal
      add :close, :decimal
      add :volume, :decimal
      add :uOpen, :decimal
      add :uHigh, :decimal
      add :uLow, :decimal
      add :uClose, :decimal
      add :uVolume, :decimal
      add :change, :decimal
      add :changePercent, :decimal
      add :label, :string
      add :changeOverTime, :decimal

      timestamps()
    end

    create unique_index(:iexc_historical_prices, [:symbol, :date], name: :iexc_historical_prices_symbol_date_index)
  end
end
